package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ResourceOpened;
import hide.domain.services.ILanguageServer;
import hide.domain.services.Diagnostic;
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
    private var eventSubscription:CallbackLink;

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
        // Подписка на события
        var eventBus = UseService.eventBus();
        eventSubscription = eventBus.subscribe(ResourceOpened, function(e:ResourceOpened) {
            trace('📂 [EditorView] Resource opened: ' + e.path);
            openFile(e.path);
        });
        
        // ✅ ИНИЦИАЛИЗАЦИЯ В ПРАВИЛЬНОМ ПОРЯДКЕ
        haxe.Timer.delay(function() {
            initEditor();
            initLsp();
        }, 100);
    }

    private function initEditor():Void {
        var container = editorContainerRef.current;
        if (container == null) {
            trace('❌ [EditorView] Editor container is null');
            return;
        }
        
        editorAdapter = new hide.infrastructure.external.MonacoEditorAdapter(container);
        // ✅ Ждём пока редактор создастся перед подпиской
        haxe.Timer.delay(function() {
            editorAdapter.onContentChanged(function() {
                var newContent = editorAdapter.getValue();
                if (!state.isDirty) {
                    setState(function(prevState:EditorViewState) {
                        return {
                            currentFile: prevState.currentFile,
                            content: newContent,
                            isDirty: true,
                            language: prevState.language,
                            lspConnected: prevState.lspConnected
                        };
                    });
                }
            });
            trace("✅ [EditorView] Content change handler attached");
        }, 300); // Увеличиваем задержку чтобы редактор точно создался
        /*
        // ✅ ИСПОЛЬЗУЕМ onContentChanged из адаптера (он сам уведомляет LSP)
        editorAdapter.onContentChanged(function() {
            var newContent = editorAdapter.getValue();
            // ✅ Используем setState с функцией для избежания stale closure
            setState(function(prevState:EditorViewState) {
                return {
                    currentFile: prevState.currentFile,
                    content: newContent,
                    isDirty: true,
                    language: prevState.language,
                    lspConnected: prevState.lspConnected
                };
            });
        });*/
        
        trace('✅ [EditorView] Monaco Editor initialized');
    }

    private function initLsp():Void {
    var lsp = UseService.languageServer();
    
    if (lsp == null) {
        trace('⚠️ [EditorView] Language Server service is NULL!');
        setState({
            currentFile: state.currentFile,
            content: state.content,
            isDirty: state.isDirty,
            language: state.language,
            lspConnected: false
        });
        return;
    }
    
    lspClient = lsp;
    trace('✅ [EditorView] LSP service obtained');
    
    // ✅ ПРОВЕРЯЕМ, ЗАПУЩЕН ЛИ УЖЕ LSP
    var isRunning = lspClient.isRunning();
    if (isRunning) {
        trace('ℹ️ [EditorView] LSP already running, skipping start');
        setState({
            currentFile: state.currentFile,
            content: state.content,
            isDirty: state.isDirty,
            language: state.language,
            lspConnected: true
        });
        
        if (editorAdapter != null) {
            editorAdapter.setLanguageServer(lspClient);
        }
        return;
    }
    
    var rootPath = "D:\\Dev\\hide-electron";
    trace('🚀 [EditorView] Starting LSP for: ' + rootPath);
    
    lspClient.start(rootPath).handle(function(success) {
        if (success) {
            trace('✅ [EditorView] LSP connected successfully');
            setState({
                currentFile: state.currentFile,
                content: state.content,
                isDirty: state.isDirty,
                language: state.language,
                lspConnected: true
            });
            
            if (editorAdapter != null) {
                editorAdapter.setLanguageServer(lspClient);
                trace('✅ [EditorView] LSP passed to Monaco adapter');
            }
        } else {
            trace('❌ [EditorView] LSP failed to start');
            setState({
                currentFile: state.currentFile,
                content: state.content,
                isDirty: state.isDirty,
                language: state.language,
                lspConnected: false
            });
        }
    });
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
            var content = fileSystem.readText(new FilePath(path));
            var language = detectLanguage(path);
            
            if (editorAdapter != null) {
                // ✅ ВАЖНО: Сначала setCurrentFile (didOpen), потом setValue
                editorAdapter.setCurrentFile(path);
                editorAdapter.setLanguage(language);
                editorAdapter.setValue(content);
            }
            
            setState(function(prevState:EditorViewState) {
                return {
                    currentFile: path,
                    content: content,
                    isDirty: false,
                    language: language,
                    lspConnected: lspClient != null
                };
            });
            
            trace('📂 [EditorView] File opened: ' + path);
        } catch (e:Dynamic) {
            trace('❌ [EditorView] Open error: ' + e);
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
                        {lspStatus}
                    </span>
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
        // ✅ Отписка от событий
        if (eventSubscription != null) {
            eventSubscription.cancel();
        }
        
        // ✅ Закрываем файл в LSP
        if (lspClient != null && state.currentFile != null) {
            editorAdapter.dispose();  // Это вызовет didClose внутри адаптера
        }
        
        // ✅ Останавливаем LSP (но только если это последний EditorView)
        // lspClient.stop();  // ← НЕ вызываем здесь, т.к. LSP может использоваться другими компонентами
    }
}