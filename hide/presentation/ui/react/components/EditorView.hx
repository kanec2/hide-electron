// presentation/ui/react/components/EditorView.hx
package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ResourceOpened;

typedef EditorViewProps = {
    var initialState:Dynamic;
    var onUnmount:Void->Void;
}

typedef EditorViewState = {
    var currentFile:Null<String>;
    var content:String;
    var isDirty:Bool;
    var language:String;
    var lspConnected:Bool;
}

class EditorView extends BaseReactComponent<EditorViewProps, EditorViewState> {
    private var editorContainerRef:Dynamic;
    private var editorAdapter:Null<hide.infrastructure.external.MonacoEditorAdapter>;
    private var lspClient:Null<LspClient>;
    private var documentVersion:Int = 0;

    public function new() {
        super();
        state = {
            currentFile: null,
            content: "",
            isDirty: false,
            language: "haxe",
            lspConnected: false
        };
        editorContainerRef = untyped React.createRef();
    }

    override function componentDidMount():Void {
        var eventBus = UseService.eventBus();

        subscribe(eventBus, ResourceOpened, function(e:ResourceOpened) {
            trace('📂 [EditorView] Resource opened');
        });

        haxe.Timer.delay(function() {
            initEditor();
            initLsp();
        }, 100);
    }

    private function initEditor():Void {
        var container = editorContainerRef.current;
        if (container == null) return;

        editorAdapter = new hide.infrastructure.external.MonacoEditorAdapter(container);
        editorAdapter.setValue("// Добро пожаловать в HIDE IDE\n");

        var editor = untyped editorAdapter.editor;
        
        // Подписка на изменения контента
        editor.onDidChangeModelContent(function(_) {
            var newContent = editor.getValue();
            if (!state.isDirty) {
                setState({
                    currentFile: state.currentFile,
                    content: newContent,
                    isDirty: true,
                    language: state.language,
                    lspConnected: state.lspConnected
                });
            }
            
            // Отправляем изменения в LSP
            if (lspClient != null && state.currentFile != null) {
                documentVersion++;
                lspClient.didChange(state.currentFile, documentVersion, newContent);
            }
        });

        trace('✅ [EditorView] Monaco Editor initialized');
    }

    private function initLsp():Void {
        var lsp = UseService.languageServer();  // ← Используем интерфейс!
        var projectService = UseService.projectService();
        var project = projectService.getCurrentProject();
        
        if (project == null) return;
        
        lsp.start(project.rootPath.toString()).handle(function(success) {
            if (success) {
                trace("✅ [EditorView] LSP connected");
                registerCompletionProvider(lsp);
            }
        });
        
        lsp.onDiagnostics(function(uri, diagnostics) {
            updateDiagnostics(uri, diagnostics);
        });
    }

    private function registerCompletionProvider():Void {
        if (editorAdapter == null || lspClient == null) return;

        var monaco = untyped require('monaco-editor');
        
        monaco.languages.registerCompletionItemProvider('haxe', {
            triggerCharacters: ['.', ':'],
            provideCompletionItems: function(model:Dynamic, position:Dynamic, _:Dynamic, _:Dynamic) {
                var uri = model.uri.toString();
                var line = position.lineNumber - 1;
                var character = position.column - 1;

                return lspClient.completion(uri, line, character).then(function(result:Dynamic) {
                    if (result == null) return { suggestions: [] };

                    var items = result.items != null ? result.items : result;
                    var suggestions = [];

                    for (item in items) {
                        suggestions.push({
                            label: item.label,
                            kind: mapCompletionKind(item.kind),
                            insertText: item.insertText != null ? item.insertText : item.label,
                            detail: item.detail,
                            documentation: item.documentation,
                            range: {
                                startLineNumber: position.lineNumber,
                                startColumn: position.column,
                                endLineNumber: position.lineNumber,
                                endColumn: position.column
                            }
                        });
                    }

                    return { suggestions: suggestions };
                });
            }
        });

        trace("✅ [EditorView] Completion provider registered");
    }

    private function mapCompletionKind(lspKind:Int):Int {
        // LSP CompletionItemKind → Monaco CompletionItemKind
        return switch (lspKind) {
            case 1: 1;  // Text
            case 2: 1;  // Method
            case 3: 1;  // Function
            case 4: 4;  // Field
            case 5: 5;  // Variable
            case 6: 6;  // Class
            case 7: 8;  // Interface
            case 8: 9;  // Module
            case 9: 10; // Property
            case 10: 13; // Keyword
            case 11: 17; // Value
            case 12: 12; // Enum
            default: 0;
        };
    }

    private function updateDiagnostics(uri:String, diagnostics:Array<Dynamic>):Void {
        if (editorAdapter == null) return;

        var monaco = untyped require('monaco-editor');
        var model = editorAdapter.editor.getModel();
        
        if (model == null) return;

        var markers = [];
        for (diag in diagnostics) {
            markers.push({
                severity: mapSeverity(diag.severity),
                message: diag.message,
                startLineNumber: diag.range.start.line + 1,
                startColumn: diag.range.start.character + 1,
                endLineNumber: diag.range.end.line + 1,
                endColumn: diag.range.end.character + 1
            });
        }

        monaco.editor.setModelMarkers(model, "haxe", markers);
    }

    private function mapSeverity(lspSeverity:Int):Int {
        return switch (lspSeverity) {
            case 1: 8; // Error
            case 2: 4; // Warning
            case 3: 2; // Information
            case 4: 1; // Hint
            default: 1;
        };
    }

    private function handleOpenFile():Void {
        var fileDialog = UseService.fileDialog();
        fileDialog.showOpen({
            filters: [
                {name: "Haxe Files", extensions: ["hx", "hxml"]},
                {name: "All Files", extensions: ["*"]}
            ]
        }).handle(function(path:Null<String>) {
            if (path != null) {
                openFile(path);
            }
        });
    }

    private function openFile(path:String):Void {
        var fileSystem = UseService.fileSystem();
        try {
            var content = fileSystem.readText(new hide.domain.valueobjects.FilePath(path));
            var language = detectLanguage(path);
            
            if (editorAdapter != null) {
                editorAdapter.setValue(content);
                editorAdapter.setLanguage(language);
            }

            // Уведомляем LSP об открытии файла
            if (lspClient != null) {
                var uri = "file://" + path;
                documentVersion = 1;
                lspClient.didOpen(uri, language, documentVersion, content);
            }

            setState({
                currentFile: path,
                content: content,
                isDirty: false,
                language: language,
                lspConnected: state.lspConnected
            });

            trace('📂 [EditorView] File opened: $path');
        } catch (e:Dynamic) {
            trace('❌ [EditorView] Open error: $e');
        }
    }

    private function detectLanguage(path:String):String {
        var ext = path.split('.').pop().toLowerCase();
        return switch (ext) {
            case 'hx', 'hxml': 'haxe';
            case 'json': 'json';
            case 'xml': 'xml';
            default: 'plaintext';
        };
    }

    override function render():ReactElement {
        var fileName = state.currentFile != null ? state.currentFile.split('/').pop() : "Untitled";
        var dirtyIndicator = state.isDirty ? " ●" : "";
        var lspStatus = state.lspConnected ? "✅ LSP" : "⚠️ No LSP";

        return jsx('
            <div style={{display: "flex", flexDirection: "column", height: "100%", background: "#1e1e1e"}}>
                <div style={{
                    padding: "8px 12px",
                    background: "#2d2d2d",
                    borderBottom: "1px solid #3e3e3e",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px"
                }}>
                    <button onClick={handleOpenFile} style={{
                        background: "#0e639c", color: "#fff", border: "none",
                        padding: "4px 12px", borderRadius: "3px", cursor: "pointer"
                    }}>
                        📂 Open
                    </button>
                    <div style={{flex: 1}}></div>
                    <span style={{color: "#888", fontSize: "11px"}}>{lspStatus}</span>
                    <span style={{color: "#ccc", fontSize: "12px"}}>
                        {fileName}{dirtyIndicator}
                    </span>
                    <span style={{color: "#888", fontSize: "11px", marginLeft: "12px"}}>
                        {state.language.toUpperCase()}
                    </span>
                </div>
                <div ref={editorContainerRef} style={{flex: 1, overflow: "hidden"}} />
            </div>
        ');
    }

    override function componentWillUnmount():Void {
        if (lspClient != null) {
            if (state.currentFile != null) {
                var uri = "file://" + state.currentFile;
                lspClient.didClose(uri);
            }
            lspClient.stop();
        }
        
        if (editorAdapter != null) {
            editorAdapter.dispose();
        }
    }
}