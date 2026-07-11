package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.domain.services.ILanguageServer;
import hide.infrastructure.external.monaco.MonacoEditorReact.MonacoEditor;
import hide.infrastructure.external.monaco.MonacoEditorReact.MonacoLoader;

typedef MonacoEditorViewProps = {
    var initialState:Dynamic;
    var onUnmount:Void->Void;
}

typedef MonacoEditorViewState = {
    var currentFile:Null<String>;
    var content:String;
    var isDirty:Bool;
    var language:String;
    var lspConnected:Bool;
    var lspStatus:String;
}

class MonacoEditorView extends BaseReactComponent<MonacoEditorViewProps, MonacoEditorViewState> {
    // ✅ Используем ref вместо state для editor и monaco
    private var editorRef:Null<Dynamic>;
    private var monacoRef:Null<Dynamic>;
    private var lspClient:Null<ILanguageServer>;
    private var documentVersion:Int = 0;

    public function new() {
        super();
        state = {
            currentFile: null,
            content: "// Welcome to HIDE IDE\n",
            isDirty: false,
            language: "haxe",
            lspConnected: false,
            lspStatus: "Initializing..."
        };
        editorRef = null;
        monacoRef = null;
    }

    override function componentDidMount():Void {
        configureMonacoLoader();
        initLsp();
    }

    private function configureMonacoLoader():Void {
        untyped __js__("
            const path = require('path');
            const { loader } = require('@monaco-editor/react');
            
            function ensureFirstBackSlash(str) {
                return str.length > 0 && str.charAt(0) !== '/' ? '/' + str : str;
            }
            
            function uriFromPath(_path) {
                const pathName = path.resolve(_path).replace(/\\\\/g, '/');
                return encodeURI('file://' + ensureFirstBackSlash(pathName));
            }
            
            loader.config({
                paths: {
                    vs: uriFromPath(path.join(__dirname, '../node_modules/monaco-editor/min/vs'))
                }
            });
        ");
        
        trace("✅ [MonacoEditorView] Monaco loader configured for Electron");
    }

    private function initLsp():Void {
        var lsp = UseService.languageServer();
        
        if (lsp == null) {
            trace('⚠️ [MonacoEditorView] Language Server service is NULL!');
            return;
        }
        
        lspClient = lsp;
        trace('✅ [MonacoEditorView] LSP service obtained');
        
        var rootPath = "D:\\Dev\\hide-electron";
        trace('🚀 [MonacoEditorView] Starting LSP for: ' + rootPath);
        
        lspClient.start(rootPath).handle(function(success) {
            if (success) {
                trace('✅ [MonacoEditorView] LSP connected successfully');
                setState({
                    currentFile: state.currentFile,
                    content: state.content,
                    isDirty: state.isDirty,
                    language: state.language,
                    lspConnected: true,
                    lspStatus: "✅ LSP Connected"
                });
                
                // ✅ Проверяем ref, а не state
                if (editorRef != null && monacoRef != null) {
                    registerLspProviders();
                }
            } else {
                trace('❌ [MonacoEditorView] LSP failed to start');
                setState({
                    currentFile: state.currentFile,
                    content: state.content,
                    isDirty: state.isDirty,
                    language: state.language,
                    lspConnected: false,
                    lspStatus: "❌ LSP Failed"
                });
            }
        });
    }

    private function registerLspProviders():Void {
        // ✅ Используем ref вместо state
        if (editorRef == null || monacoRef == null) {
            trace('⚠️ [MonacoEditorView] Editor not mounted yet, deferring LSP registration');
            return;
        }
        
        var monaco = monacoRef;
        var editor = editorRef;
        
        trace('✅ [MonacoEditorView] Registering LSP providers');
        
        // Completion Provider
        untyped monaco.languages.registerCompletionItemProvider('haxe', {
            provideCompletionItems: function(model, position) {
                if (lspClient == null) return { suggestions: [] };
                
                var uri = model.uri.toString();
                var result = lspClient.completion(uri, position.lineNumber - 1, position.column - 1);
                
                return untyped __js__("new Promise((resolve) => {
                    result.handle(function(items) {
                        if (!items) resolve({ suggestions: [] });
                        else {
                            var suggestions = items.map(function(item) {
                                return {
                                    label: item.label,
                                    kind: monaco.languages.CompletionItemKind[item.kind] || monaco.languages.CompletionItemKind.Text,
                                    insertText: item.insertText || item.label,
                                    detail: item.detail,
                                    documentation: item.documentation
                                };
                            });
                            resolve({ suggestions: suggestions });
                        }
                    });
                })");
            }
        });
        
        // Hover Provider
        untyped monaco.languages.registerHoverProvider('haxe', {
            provideHover: function(model, position) {
                if (lspClient == null) return null;
                
                var uri = model.uri.toString();
                var result = lspClient.hover(uri, position.lineNumber - 1, position.column - 1);
                
                return untyped __js__("new Promise((resolve) => {
                    result.handle(function(hover) {
                        if (!hover) resolve(null);
                        else {
                            resolve({
                                contents: [{ value: hover.contents }]
                            });
                        }
                    });
                })");
            }
        });
        
        // Definition Provider
        untyped monaco.languages.registerDefinitionProvider('haxe', {
            provideDefinition: function(model, position) {
                if (lspClient == null) return null;
                
                var uri = model.uri.toString();
                var result = lspClient.definition(uri, position.lineNumber - 1, position.column - 1);
                
                return untyped __js__("new Promise((resolve) => {
                    result.handle(function(def) {
                        if (!def) resolve(null);
                        else {
                            resolve({
                                uri: monaco.Uri.parse(def.uri),
                                range: {
                                    startLineNumber: def.range.start.line + 1,
                                    startColumn: def.range.start.character + 1,
                                    endLineNumber: def.range.end.line + 1,
                                    endColumn: def.range.end.character + 1
                                }
                            });
                        }
                    });
                })");
            }
        });
        
        trace('✅ [MonacoEditorView] All LSP providers registered');
    }

    private function handleEditorDidMount(editor:Dynamic, monaco:Dynamic):Void {
        trace('✅ [MonacoEditorView] Editor mounted');
        
        // ✅ Сохраняем в ref, а не в state
        editorRef = editor;
        monacoRef = monaco;
        
        // ✅ Проверяем ref, а не state
        if (lspClient != null) {
            registerLspProviders();
        }
    }

    private function handleEditorChange(value:String, event:Dynamic):Void {
        setState({
            currentFile: state.currentFile,
            content: value,
            isDirty: true,
            language: state.language,
            lspConnected: state.lspConnected,
            lspStatus: state.lspStatus
        });
        
        if (lspClient != null && state.currentFile != null) {
            documentVersion++;
            lspClient.didChange(state.currentFile, documentVersion, value);
        }
    }

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
            var content = fileSystem.readText(new hide.domain.valueobjects.FilePath(path));
            var language = detectLanguage(path);
            
            if (lspClient != null && state.currentFile != null) {
                lspClient.didClose(state.currentFile);
            }
            
            var normalizedPath = path.split("\\").join("/");
            if (!StringTools.startsWith(normalizedPath, "/")) {
                normalizedPath = "/" + normalizedPath;
            }
            var uri = "file://" + normalizedPath;
            
            if (lspClient != null) {
                documentVersion = 1;
                lspClient.didOpen(uri, language, documentVersion, content);
                trace('📂 [MonacoEditorView] File opened: ' + uri);
            }
            
            setState({
                currentFile: uri,
                content: content,
                isDirty: false,
                language: language,
                lspConnected: state.lspConnected,
                lspStatus: state.lspStatus
            });
            
            trace('📂 [MonacoEditorView] File opened: ' + path);
        } catch (e:Dynamic) {
            trace('❌ [MonacoEditorView] Open error: ' + e);
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
                        background: "#0e639c",
                        color: "#fff",
                        border: "none",
                        padding: "4px 12px",
                        borderRadius: "3px",
                        cursor: "pointer"
                    }}>
                        📂 Open
                    </button>
                    <div style={{flex: 1}}></div>
                    <span style={{color: state.lspConnected ? "#4caf50" : "#f44336", fontSize: "11px"}}>
                        {state.lspStatus}
                    </span>
                    <span style={{color: "#ccc", fontSize: "12px"}}>
                        {fileName}{dirtyIndicator}
                    </span>
                    <span style={{color: "#888", fontSize: "11px", marginLeft: "12px"}}>
                        {state.language.toUpperCase()}
                    </span>
                </div>
                <div style={{flex: 1, overflow: "hidden"}}>
                    <MonacoEditor
                        height="100%"
                        language={state.language}
                        value={state.content}
                        theme="vs-dark"
                        onChange={handleEditorChange}
                        onMount={handleEditorDidMount}
                        options={{
                            automaticLayout: true,
                            minimap: { enabled: true },
                            fontSize: 14,
                            lineNumbers: "on",
                            scrollBeyondLastLine: true,
                            renderWhitespace: "selection",
                            wordWrap: "off",
                            tabSize: 4,
                            insertSpaces: true,
                            formatOnPaste: true,
                            formatOnType: true
                        }}
                    />
                </div>
            </div>
        ');
    }

    override function componentWillUnmount():Void {
        if (lspClient != null) {
            if (state.currentFile != null) {
                lspClient.didClose(state.currentFile);
            }
            lspClient.stop();
        }
    }
}