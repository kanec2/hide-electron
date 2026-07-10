package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ResourceOpened;
import hide.domain.services.ILanguageServer;
import hide.domain.services.ILanguageServer.Diagnostic;
import hide.domain.valueobjects.FilePath;
import tink.core.*;
using tink.CoreApi;

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
    private var lspClient:Null<ILanguageServer>;
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
        
        editorAdapter.onDidChangeModelContent(function(_) {
            var newContent = editorAdapter.getValue();
            if (!state.isDirty) {
                setState({
                    currentFile: state.currentFile,
                    content: newContent,
                    isDirty: true,
                    language: state.language,
                    lspConnected: state.lspConnected
                });
            }
            if (lspClient != null && state.currentFile != null) {
                documentVersion++;
                var uri = "file:///" + state.currentFile.split("\\").join("/");
                lspClient.didChange(uri, documentVersion, newContent);
            }
        });
        trace('✅ [EditorView] Monaco Editor initialized');
    }

    private function initLsp():Void {
        var lsp = UseService.languageServer();
        if (lsp == null) {
            trace('⚠️ [EditorView] Language Server not available');
            return;
        }
        lspClient = lsp;
        
        var rootPath = "D:\\Dev\\hide-electron";
        lspClient.start(rootPath).handle(function(success) {
            if (success) {
                trace("✅ [EditorView] LSP connected");
                setState({
                    currentFile: state.currentFile,
                    content: state.content,
                    isDirty: state.isDirty,
                    language: state.language,
                    lspConnected: true
                });
                
                // ✅ КРИТИЧНО: передаём LSP в адаптер!
                // Адаптер сам зарегистрирует все провайдеры
                if (editorAdapter != null) {
                    editorAdapter.setLanguageServer(lsp);
                }
            } else {
                trace("❌ [EditorView] LSP failed to start");
            }
        });
        
        // ✅ Diagnostics подписка остаётся здесь, 
        // потому что это UI-логика (обновление маркеров в Monaco)
        // НО! Она уже есть в setLanguageServer() — можно убрать дубликат
        trace('✅ [EditorView] LSP client initialized');
    }

    // ❌ УДАЛЕНО: registerCompletionProvider() — теперь в адаптере
    // ❌ УДАЛЕНО: mapCompletionKind() — теперь в адаптере
    // ❌ УДАЛЕНО: updateDiagnostics() — теперь в адаптере
    // ❌ УДАЛЕНО: mapSeverity() — теперь в адаптере

    private function handleOpenFile():Void {
        var fileDialog = UseService.fileDialog();
        fileDialog.showOpen({
            filters: [
                {name: "Haxe Files", extensions: ["hx", "hxml"]},
                {name: "All Files", extensions: ["*"]}
            ]
        }).handle(function(path:Null<String>) {
            if (path != null) openFile(path);
        });
    }

    private function openFile(path:String):Void {
        var fileSystem = UseService.fileSystem();
        try {
            var content = fileSystem.readText(new FilePath(path));
            var language = detectLanguage(path);
            if (editorAdapter != null) {
                editorAdapter.setValue(content);
                editorAdapter.setLanguage(language);
                // ✅ Уведомляем адаптер о новом файле (он сам уведомит LSP)
                editorAdapter.setCurrentFile(path);
            }
            setState({
                currentFile: path,
                content: content,
                isDirty: false,
                language: language,
                lspConnected: lspClient != null
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
                    padding: "8px 12px", background: "#2d2d2d",
                    borderBottom: "1px solid #3e3e3e",
                    display: "flex", alignItems: "center", gap: "8px"
                }}>
                    <button onClick={handleOpenFile} style={{
                        background: "#0e639c", color: "#fff", border: "none",
                        padding: "4px 12px", borderRadius: "3px", cursor: "pointer"
                    }}>Open</button>
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
                var uri = "file:///" + state.currentFile.split("\\").join("/");
                lspClient.didClose(uri);
            }
            lspClient.stop();
        }
        if (editorAdapter != null) editorAdapter.dispose();
    }
}