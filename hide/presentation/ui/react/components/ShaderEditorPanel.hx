// hide/presentation/ui/react/components/ShaderEditorPanel.hx
package hide.presentation.ui.react.components;

import hide.domain.valueobjects.FilePath;
import hide.engine.infrastructure.ShaderGraphCompiler;
import hide.engine.infrastructure.ShaderNodeRegistry;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import hide.application.services.ShaderHistoryService;
import hide.application.commands.SaveShaderUseCase;
import hide.application.commands.LoadShaderUseCase;
import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.infrastructure.external.litegraph.*;
import hide.presentation.ui.react.components.ShaderNodePalette;
import hide.engine.infrastructure.ShaderGraphSerializer;
typedef ShaderEditorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}
typedef ShaderEditorState = {
    var graph: Dynamic;
    var selectedNode: Dynamic;
}
/**
    Редактор шейдеров на основе LiteGraph.
    Отвечает за UI-рендеринг и координацию работы с графом.
*/
class ShaderEditorPanel extends BaseReactComponent<ShaderEditorProps, ShaderEditorState> {
    private var liteGraphCanvas:js.html.CanvasElement;
    private var graph:LGraph;
    private var graphCanvas:LGraphCanvas;
    private var previewRenderer:ShaderPreviewRenderer;
    private var litegraphContainerRef:Dynamic;

    // Сервисы
    private var compiler:ShaderGraphCompiler;
    private var historyService:ShaderHistoryService;
    private var nodeRegistry:ShaderNodeRegistry;
    private var saveUseCase:SaveShaderUseCase;
    private var loadUseCase:LoadShaderUseCase;

    // Состояние файла
    private var currentFilePath:Null<String> = null;
    private var isDirty:Bool = false;

    // Таймер для дебаунса
    private var recompileTimer:Null<haxe.Timer> = null;

    public function new() {
        super();
        
        // Получаем сервисы из DI
        previewRenderer = UseService.shaderPreviewRenderer();
        compiler = new ShaderGraphCompiler();
        historyService = UseService.shaderHistory();
        nodeRegistry = UseService.shaderNodeRegistry();
        saveUseCase = UseService.saveShader();
        loadUseCase = UseService.loadShader();
        
        litegraphContainerRef = untyped React.createRef();
        state = { graph: null, selectedNode: null };
    }

    override function componentDidMount():Void {
        initLiteGraph();
        
        // Асинхронная инициализация превью
        haxe.Timer.delay(function() {
            previewRenderer.init();
            
            var viewportService = UseService.viewportService();
            
            haxe.Timer.delay(function() {
                var previewContainer = js.Browser.document.getElementById("heaps-preview-container");
                
                if (previewContainer != null) {
                    var rect = previewContainer.getBoundingClientRect();
                    var w = Std.int(rect.width);
                    var h = Std.int(rect.height);
                    
                    if (w < 50) w = 300;
                    if (h < 50) h = 300;
                    
                    var vp = viewportService.register("shader-preview", previewRenderer.scene, w, h);
                    
                    if (vp != null && vp.canvas != null) {
                        previewContainer.appendChild(vp.canvas);
                        vp.canvas.style.width = "100%";
                        vp.canvas.style.height = "100%";
                        vp.canvas.style.display = "block";
                        vp.canvas.style.imageRendering = "pixelated";
                        
                        previewRenderer.setupOrbitControls(vp.canvas);
                        
                        trace('✅ [ShaderPanel] Canvas appended with orbit controls');
                    }
                }
            }, 16);
        }, 16);
        
        setupGraphListeners();
        setupKeyboardShortcuts();
        
        // Регистрируем глобальную функцию для диалога выбора текстуры
        untyped js.Browser.window.__browseShaderTexture = function(node:Dynamic) {
            var fileDialog = UseService.fileDialog();
            fileDialog.showOpen({
                filters: [
                    { name: "Images", extensions: ["png", "jpg", "jpeg", "dds", "hdr", "tga"] }
                ]
            }).handle(function(path:Null<String>) {
                if (path != null) {
                    node.properties.texture = path;
                    node.setDirtyCanvas(true, true);
                    scheduleRecompile();
                    trace('🖼️ [ShaderEditor] Texture selected: $path');
                }
            });
        };
    }

    // === Клавиатурные шорткаты ===

    private function setupKeyboardShortcuts():Void {
        js.Browser.window.addEventListener("keydown", function(e:js.html.KeyboardEvent) {
            var ctrl = e.ctrlKey || e.metaKey;
            
            if (ctrl && !e.shiftKey) {
                switch (e.key.toLowerCase()) {
                    case "s":
                        e.preventDefault();
                        onSave();
                    case "o":
                        e.preventDefault();
                        onLoad();
                    case "z":
                        e.preventDefault();
                        onUndo();
                    case "y":
                        e.preventDefault();
                        onRedo();
                    case "n":
                        e.preventDefault();
                        onNew();
                }
            }
            
            if (ctrl && e.shiftKey && e.key.toLowerCase() == "s") {
                e.preventDefault();
                onSaveAs();
            }
        });
    }

    // === Файловые операции ===

    private function onSave():Void {
        if (graph == null) return;
        
        if (currentFilePath != null) {
            saveToFile(currentFilePath);
        } else {
            onSaveAs();
        }
    }

    private function onSaveAs():Void {
        if (graph == null) return;
        
        saveUseCase.saveAs(graph, graphCanvas).handle(function(path:Null<String>) {
            if (path != null) {
                currentFilePath = path;
                isDirty = false;
                updateTitle();
            }
        });
    }

    private function saveToFile(path:String):Void {
        switch (saveUseCase.saveToPath(graph, graphCanvas, path)) {
            case Success(p):
                currentFilePath = p;
                isDirty = false;
                updateTitle();
            case Failure(e):
                trace("❌ [ShaderEditor] Save error: " + e);
        }
    }

    private function onLoad():Void {
        if (graph == null) return;
        
        loadUseCase.loadWithDialog(graph, graphCanvas).handle(function(path:Null<String>) {
            if (path != null) {
                currentFilePath = path;
                isDirty = false;
                updateTitle();
                restoreNodeCallbacks();
                compileAndApply();
            }
        });
    }

    private function restoreNodeCallbacks():Void {
        var nodes:Array<Dynamic> = untyped graph._nodes;
        if (nodes == null) return;
        
        for (node in nodes) {
            untyped node.onConnectionsChange = function(type:Int, slot:Int, isConnected:Bool, link_info:Dynamic, input_info:Dynamic) {
                trace('🔗 [ShaderEditor] Connection changed on node: ${node.title}');
                scheduleRecompile();
            };
        }
        trace('✅ [ShaderEditor] Restored callbacks on ${nodes.length} nodes');
    }

    // === Слушатели изменений графа ===

    private function setupGraphListeners():Void {
        if (graph == null) return;
        
        var onGraphChanged = function() {
            if (historyService.get_isInProgress()) return;
            
            historyService.saveState(graph);
            
            if (!isDirty) {
                isDirty = true;
                updateTitle();
            }
            scheduleRecompile();
        };
        
        graph.onAfterStep = function() scheduleRecompile();
        graph.onNodeAdded = function(_) onGraphChanged();
        graph.onNodeRemoved = function(_) onGraphChanged();
        
        untyped graph.onConnectionChange = function(node:Dynamic, action:String, link:Dynamic) {
            haxe.Timer.delay(onGraphChanged, 100);
        };
        
        untyped graph.onNodeChanged = function(_) onGraphChanged();
    }

    private function scheduleRecompile():Void {
        if (recompileTimer != null) {
            recompileTimer.stop();
        }
        recompileTimer = haxe.Timer.delay(compileAndApply, 100);
    }

    // === Компиляция графа ===

    private function compileAndApply():Void {
        trace("🔨 [ShaderEditor] Recompiling shader graph...");
        if (graph == null || previewRenderer == null) return;
        
        var shaderData = compiler.compile(graph);
        
        // Применяем к превью
        previewRenderer.updateMaterial({
            albedo: shaderData.albedo,
            metallic: shaderData.metallic,
            roughness: shaderData.roughness,
            normal: shaderData.normal,
            emissive: shaderData.emissive
        });
        
        trace("✅ [ShaderEditor] PBR Shader updated");
    }

    // === Инициализация LiteGraph ===

    private function initLiteGraph():Void {
        var container:js.html.Element = litegraphContainerRef.current;
        if (container == null) {
            trace("❌ [ShaderEditor] #litegraph-container not found!");
            return;
        }
        
        haxe.Timer.delay(function() {
            var rect = container.getBoundingClientRect();
            var w = Std.int(rect.width);
            var h = Std.int(rect.height);
            
            if (w < 100 || h < 100) {
                trace('⚠️ [ShaderEditor] Container too small: ${w}x${h}, retrying...');
                haxe.Timer.delay(function() initLiteGraph(), 100);
                return;
            }
            
            trace('📐 [ShaderEditor] Container size: ${w}x${h}');
            
            liteGraphCanvas = cast js.Browser.document.createElement("canvas");
            liteGraphCanvas.id = "shader-graph-canvas";
            liteGraphCanvas.width = w;
            liteGraphCanvas.height = h;
            
            container.appendChild(liteGraphCanvas);
            
            liteGraphCanvas.addEventListener("click", function(e:js.html.MouseEvent) {
                if (graphCanvas.selected_nodes != null) {
                    var keys = Reflect.fields(graphCanvas.selected_nodes);
                    if (keys.length > 0) {
                        var firstKey = keys[0];
                        var selected = Reflect.field(graphCanvas.selected_nodes, firstKey);
                        setState({
                            graph: graph,
                            selectedNode: selected
                        });
                    } else {
                        setState({
                            graph: graph,
                            selectedNode: null
                        });
                    }
                } else {
                    setState({
                        graph: graph,
                        selectedNode: null
                    });
                }
            });
            
            graph = new LGraph();
            graphCanvas = new LGraphCanvas(liteGraphCanvas, graph);
            graphCanvas.show_info = true;
            graphCanvas.allow_dragcanvas = true;
            graphCanvas.allow_zoomcanvas = true;
            graphCanvas.resize(w, h);
            
            setupDragAndDrop(container);
            
            graphCanvas.onSelectionChange = function(nodes:Dynamic) {
                if (nodes != null) {
                    var keys = Reflect.fields(nodes);
                    if (keys.length > 0) {
                        var firstKey = keys[0];
                        var node = Reflect.field(nodes, firstKey);
                        setState({
                            graph: graph,
                            selectedNode: node
                        });
                    } else {
                        setState({
                            graph: graph,
                            selectedNode: null
                        });
                    }
                } else {
                    setState({
                        graph: graph,
                        selectedNode: null
                    });
                }
            };
            
            graphCanvas.onNodeMoved = function(node:LGraphNode) {
                if (!historyService.get_isInProgress()) {
                    historyService.saveState(graph);
                    if (!isDirty) {
                        isDirty = true;
                        updateTitle();
                    }
                }
                
                if (graphCanvas.selected_nodes != null) {
                    var keys = Reflect.fields(graphCanvas.selected_nodes);
                    if (keys.length > 0) {
                        var firstKey = keys[0];
                        var selected = Reflect.field(graphCanvas.selected_nodes, firstKey);
                        setState({
                            graph: graph,
                            selectedNode: selected
                        });
                    }
                }
            };
            
            // Регистрируем ноды через сервис
            nodeRegistry.registerAll();
            
            // Создаём Material Output через сервис
            var outputNode = nodeRegistry.createMaterialOutput(graph, function(_) scheduleRecompile(), w, h);
            
            // Сохраняем начальное состояние
            haxe.Timer.delay(function() {
                historyService.saveState(graph);
                trace('✅ [ShaderEditor] Initial undo state saved');
            }, 200);
            
            graph.start();
            
            state = { graph: graph, selectedNode: null };
            trace("✅ [ShaderEditor] LiteGraph initialized");
        }, 100);
    }

    private function setupDragAndDrop(container:js.html.Element):Void {
        container.addEventListener("dragover", function(e:js.html.DragEvent) {
            e.preventDefault();
            e.dataTransfer.dropEffect = "copy";
        });
        
        container.addEventListener("drop", function(e:js.html.DragEvent) {
            e.preventDefault();
            var nodeType = e.dataTransfer.getData("nodeType");
            if (nodeType != null && nodeType != "") {
                var graphPos = graphCanvas.convertEventToCanvasOffset(e);
                var node = LiteGraph.createNode(nodeType);
                if (node != null) {
                    node.pos = [graphPos[0], graphPos[1]];
                    
                    untyped node.onConnectionsChange = function(type:Int, slot:Int, isConnected:Bool, link_info:Dynamic, input_info:Dynamic) {
                        scheduleRecompile();
                    };
                    
                    graph.add(node);
                    trace("✅ Node created: " + nodeType);
                }
            }
        });
    }

    // === UI-рендеринг ===

    override function render():ReactElement {
        return jsx('
            <div style={{display: "flex", height: "100%", flexDirection: "column"}}>
                {renderToolbar()}
                {renderMainArea()}
            </div>
        ');
    }

    private function renderToolbar():ReactElement {
        return jsx('
            <div style={{padding: "8px", background: "#2a2a2a", borderBottom: "1px solid #1a1a1a", display: "flex", gap: "8px"}}>
                <button onClick={onNew}>New</button>
                <button onClick={onLoad}>Load</button>
                <button onClick={onSave}>Save</button>
                <button onClick={onSaveAs}>Save As</button>
                <div style={{width: "1px", background: "#444"}}></div>
                <button onClick={onUndo}>Undo</button>
                <button onClick={onRedo}>Redo</button>
                <div style={{flex: 1}}></div>
                <button onClick={onCompile}>Compile</button>
                <button onClick={onExportHLSL}>Export HLSL</button>
                <button onClick={onClearGraph}>Clear</button>
            </div>
        ');
    }

    private function renderMainArea():ReactElement {
        return jsx('
            <div style={{display: "flex", flex: 1, overflow: "hidden"}}>
                {renderNodePalette()}    
                {renderNodeEditor()}
                {renderRightPanel()}
            </div>
        ');
    }

    private function renderNodeEditor():ReactElement {
        return jsx('
            <div ref={litegraphContainerRef}
                style={{flex: 1, position: "relative", background: "#1a1a1a"}}>
            </div>
        ');
    }

    private function renderNodePalette():ReactElement {
        return jsx('
            <ShaderNodePalette 
                onNodeDragStart={function(nodeType:String) {
                    trace("📦 Dragging node: " + nodeType);
                }}
            />
        ');
    }

    private function renderRightPanel():ReactElement {
        return jsx('
            <div style={{
                width: "400px", 
                display: "flex", 
                flexDirection: "column", 
                borderLeft: "1px solid #1a1a1a"
            }}>
                {renderPreview()}
                {renderProperties()}
            </div>
        ');
    }

    private function renderPreview():ReactElement {
        return jsx('
            <div style={{
                    height: "400px",
                    background: "#1a1a1a",
                    position: "relative",
                    border: "1px solid #333"
                }}>
                <div id="heaps-preview-container" 
                    style={{width: "100%", 
                    height: "100%", 
                    display: "block",
                    background: "#1a1a1a",
                    imageRendering: "crisp-edges" }}>
                </div>
                <div style={{
                    position: "absolute",
                    top: "8px",
                    right: "8px",
                    padding: "4px 8px",
                    background: "rgba(0,0,0,0.5)",
                    color: "#fff",
                    fontSize: "12px",
                    borderRadius: "3px"
                }}>
                    Preview
                </div>
            </div>
        ');
    }

    private function renderProperties():ReactElement {
        return jsx('
            <div style={{flex: 1, padding: "10px", background: "#2a2a2a", overflowY: "auto"}}>
                <h3 style={{margin: "0 0 10px 0", color: "#fff", fontSize: "14px"}}>
                    Properties
                </h3>
                <NodePropertiesPanel 
                    selectedNode={state.selectedNode}
                    onPropertyChange={onNodePropertyChanged}
                />
            </div>
        ');
    }

    private function onNodePropertyChanged():Void {
        if (historyService.get_isInProgress()) return;
        
        historyService.saveState(graph);
        trace("🔄 [ShaderEditor] Node property changed, recompiling...");
        if (!isDirty) {
            isDirty = true;
            updateTitle();
        }
        compileAndApply();
    }

    private function updateTitle():Void {
        var filename = currentFilePath != null ? currentFilePath.split("/").pop() : "Untitled";
        var dirty = isDirty ? " ●" : "";
        var title = '${filename}${dirty} - Shader Editor';
        
        UseService.windowService().setTitle(title);
        trace('🏷️ [ShaderEditor] Title: $title');
    }

    // === Действия toolbar ===

    private function onNew():Void {
        if (isDirty) {
            var confirmed = js.Browser.window.confirm("Unsaved changes will be lost. Continue?");
            if (!confirmed) return;
        }
        graph.clear();
        currentFilePath = null;
        isDirty = false;
        updateTitle();
        
        var w = liteGraphCanvas.width;
        var h = liteGraphCanvas.height;
        var outputNode = nodeRegistry.createMaterialOutput(graph, function(_) scheduleRecompile(), w, h);
        
        trace("🆕 [ShaderEditor] New graph");
    }

    private function onUndo():Void {
        historyService.undo(graph, function() {
            restoreNodeCallbacks();
            if (!isDirty) {
                isDirty = true;
                updateTitle();
            }
            compileAndApply();
        });
    }

    private function onRedo():Void {
        historyService.redo(graph, function() {
            restoreNodeCallbacks();
            if (!isDirty) {
                isDirty = true;
                updateTitle();
            }
            compileAndApply();
        });
    }

    private function onCompile():Void {
        trace("🔨 Compile shader graph");
        compileAndApply();
    }

    private function onExportHLSL():Void {
        trace("📤 Export HLSL");
    }

    private function onClearGraph():Void {
        if (graph != null) {
            graph.clear();
            trace("🧹 Graph cleared");
        }
    }

    override function componentWillUnmount():Void {
        if (graph != null) graph.stop();
        previewRenderer.dispose();
        untyped js.Browser.window.__browseShaderTexture = null;
    }
}