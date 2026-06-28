// hide/presentation/ui/react/components/ShaderEditorPanel.hx
package hide.presentation.ui.react.components;
import hide.engine.infrastructure.ShaderGraphCompiler;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.infrastructure.external.litegraph.*;
import hide.presentation.ui.react.components.ShaderNodePalette;

typedef ShaderEditorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef ShaderEditorState = {
    var graph: Dynamic;
    var selectedNode: Dynamic; // ← НОВОЕ
}

class ShaderEditorPanel extends BaseReactComponent<ShaderEditorProps, ShaderEditorState> {
    private var liteGraphCanvas:js.html.CanvasElement;
    private var graph:LGraph;
    private var graphCanvas:LGraphCanvas;
    private var previewRenderer:ShaderPreviewRenderer; // ← инжектируем

    private var litegraphContainerRef:Dynamic;

    public function new() {
        super();
        // ✅ Получаем рендерер из DI, а не создаём h3d.Engine вручную!
        previewRenderer = UseService.shaderPreviewRenderer();
        litegraphContainerRef = untyped React.createRef();
        state = { graph: null, selectedNode: null };
    }
    
    override function componentDidMount():Void {
        initLiteGraph();
        // ✅ Передаём DOM-контейнер в engine layer
        //var previewContainer = js.Browser.document.getElementById("heaps-preview-container");
        previewRenderer.init();
        // ✅ 2. Получаем сервис вьюпортов через UseService
        // Вам нужно добавить viewportService() в UseService.hx, если его там нет
        var viewportService = UseService.viewportService(); 
        
        // ✅ 3. Регистрируем сцену превью как отдельный вьюпорт
        // Размер 400x300 соответствует контейнеру preview
        var vp = viewportService.register("shader-preview", previewRenderer.scene, 800, 600); // Было 400x300
        trace('🔍 [ShaderPanel] Viewport registered: ${vp != null}, canvas: ${vp.canvas != null}');
        // ✅ 4. Вставляем canvas вьюпорта в DOM
        // ✅ ИСПРАВЛЕНИЕ: ждём, пока React 17 завершит рендеринг DOM
        haxe.Timer.delay(function() {
            var previewContainer = js.Browser.document.getElementById("heaps-preview-container");
            trace('🔍 [ShaderPanel] previewContainer: ${previewContainer != null}');
            
            if (previewContainer != null && vp.canvas != null) {
                previewContainer.appendChild(vp.canvas);
                vp.canvas.style.width = "100%";
                vp.canvas.style.height = "100%";
                vp.canvas.style.display = "block";
                trace('✅ [ShaderPanel] Canvas appended to DOM');
            } else {
                trace('❌ [ShaderPanel] Container or canvas is NULL! ' +
                    'previewContainer=${previewContainer != null}, canvas=${vp.canvas != null}');
            }
        }, 50); // 50мс достаточно для React 17
        
        
        // ✅ НОВОЕ: Подписки на изменения графа с дебаунсом
        setupGraphListeners();
    }

    private var recompileTimer:Null<haxe.Timer> = null;

    private function setupGraphListeners():Void {
        if (graph == null) return;
        
        // Любое изменение графа → перекомпиляция с дебаунсом 100мс
        graph.onAfterStep = function() {
            scheduleRecompile();
        };
        
        // Также реагируем на конкретные события
        graph.onNodeAdded = function(_) scheduleRecompile();
        graph.onNodeRemoved = function(_) scheduleRecompile();

        // ✅ НОВОЕ: Реагируем на подключение/отключение нод С ЗАДЕРЖКОЙ
        untyped graph.onConnectionChange = function(node:Dynamic, action:String, link:Dynamic) {
            trace('🔗 [ShaderEditor] onConnectionChange called!');
            trace('   node: ${node != null ? node.title : "null"}');
            trace('   action: $action');
            trace('   link: ${link != null ? "exists" : "null"}');
            
            // ✅ ЗАДЕРЖКА: даём LiteGraph время обновить связи
            haxe.Timer.delay(scheduleRecompile, 100);
        };
        // И на изменение свойств нод (widget changes)
        // LiteGraph вызывает onNodeChanged при изменении properties
        untyped graph.onNodeChanged = function(_) scheduleRecompile();
    }

    private function scheduleRecompile():Void {
        // Отменяем предыдущий таймер (дебаунс)
        if (recompileTimer != null) {
            recompileTimer.stop();
        }
        recompileTimer = haxe.Timer.delay(compileAndApply, 100);
    }
    /*
    private function compileAndApply():Void {
        trace("🔨 [ShaderEditor] Recompiling shader graph...");
        if (graph == null || previewRenderer == null) return;
        
        // ✅ ИСПРАВЛЕНО: в LiteGraph массив нод хранится в _nodes, а не nodes
        var nodes:Dynamic = untyped graph._nodes;
        if (nodes == null) {
            // Фоллбэк: пробуем graph.nodes
            nodes = untyped graph.nodes;
        }
        
        if (nodes == null) {
            trace("⚠️ [ShaderEditor] graph._nodes is undefined, skipping compile");
            return;
        }
        
        var nodesArray:Array<Dynamic> = cast nodes;
        
        // ✅ 1. Ищем ноду Material Output
        var outputNode:Dynamic = null;
        for (node in nodesArray) {
            if (node.type == "material/output") {
                outputNode = node;
                break;
            }
        }
        if (outputNode == null) {
            trace("️ [ShaderEditor] No Material Output node found");
            return;
        }
        // ✅ ОТЛАДКА: смотрим все входы Material Output
        trace('🔍 [ShaderEditor] Material Output inputs:');
        if (outputNode.inputs != null) {
            for (i in 0...outputNode.inputs.length) {
                var input = outputNode.inputs[i];
                var link = outputNode.getInputLink(i);
                trace('   [$i] ${input.name}: linked=${link != null}');
                if (link != null) {
                    trace('       origin_id=${link.origin_id}, origin_slot=${link.origin_slot}');
                }
            }
        }
        // 2. Проверяем, что подключено к Albedo (slot 0)
        var albedoLink = outputNode.getInputLink(0);
        
        if (albedoLink == null) {
            // ✅ Ничего не подключено — сбрасываем на дефолтный цвет (серый)
            trace("⚪ [ShaderEditor] Albedo not connected — resetting to default");
            previewRenderer.updateMaterial({
                albedo: { x: 0.5, y: 0.5, z: 0.5 }
            });
            return;
        }

        // ✅ 3. Получаем ноду, подключенную к Albedo
        var sourceNode = graph.getNodeById(albedoLink.origin_id);
        
        if (sourceNode == null) {
            trace("⚠️ [ShaderEditor] Source node not found");
            previewRenderer.updateMaterial({
                albedo: { x: 0.5, y: 0.5, z: 0.5 }
            });
            return;
        }
        
        trace("🔍 [ShaderEditor] Albedo source: ${sourceNode.type} (${sourceNode.title})");
        
        // 4. Обрабатываем в зависимости от типа ноды
        if (sourceNode.type == "value/vec3") {
            var x = Reflect.field(sourceNode.properties, "x");
            var y = Reflect.field(sourceNode.properties, "y");
            var z = Reflect.field(sourceNode.properties, "z");
            
            previewRenderer.updateMaterial({
                albedo: { x: x, y: y, z: z }
            });
            
            trace('🎨 [ShaderEditor] Applied color from Vector3: ($x, $y, $z)');
        } else if (sourceNode.type == "value/color") {
            var r = Reflect.field(sourceNode.properties, "r");
            var g = Reflect.field(sourceNode.properties, "g");
            var b = Reflect.field(sourceNode.properties, "b");
            
            previewRenderer.updateMaterial({
                albedo: { x: r, y: g, z: b }
            });
            
            trace('🎨 [ShaderEditor] Applied color from Color: ($r, $g, $b)');
        } else {
            trace("⚠️ [ShaderEditor] Unsupported node type for Albedo: ${sourceNode.type}");
            previewRenderer.updateMaterial({
                albedo: { x: 0.5, y: 0.5, z: 0.5 }
            });
        }
    }*/
    private function compileAndApply():Void {
        trace("🔨 [ShaderEditor] Recompiling shader graph...");
        if (graph == null || previewRenderer == null) return;
        
        // 1. Ищем Material Output
        var outputNode:Dynamic = null;
        var nodesArray:Array<Dynamic> = untyped graph._nodes;
        if (nodesArray == null) return;
        
        for (node in nodesArray) {
            if (node.type == "material/output") {
                outputNode = node;
                break;
            }
        }
        
        if (outputNode == null) {
            trace("⚠️ [ShaderEditor] No Material Output found");
            return;
        }
        
        // 2. Вычисляем ВСЕ PBR-параметры через рекурсию
        var albedo = evaluateInput(outputNode, 0, new Map());      // slot 0 = Albedo (vec3)
        var metallic = evaluateInput(outputNode, 1, new Map());    // slot 1 = Metallic (float)
        var roughness = evaluateInput(outputNode, 2, new Map());   // slot 2 = Roughness (float)
        var normal = evaluateInput(outputNode, 3, new Map());      // slot 3 = Normal (vec3) - пока игнорируем
        var emissive = evaluateInput(outputNode, 4, new Map());    // slot 4 = Emissive (vec3)
        
        trace('📊 [ShaderEditor] PBR Evaluated:');
        trace('   Albedo: $albedo');
        trace('   Metallic: $metallic');
        trace('   Roughness: $roughness');
        trace('   Emissive: $emissive');
        
        // 3. Применяем к превью
        previewRenderer.updateMaterial({
            albedo: albedo,
            metallic: metallic,
            roughness: roughness,
            emissive: emissive
        });
        
        trace("✅ [ShaderEditor] PBR Shader updated");
    }
    /**
     * Рекурсивно вычисляет значение выхода ноды.
     * Возвращает:
     *   - Float для value/float
     *   - {x, y, z} для value/vec3, value/color
     *   - результат операции для math/operation
     *   - null если не вычислили
     */
    private function evaluateNode(node:Dynamic, outputSlot:Int, ?visited:Map<Int, Bool>):Dynamic {
        if (node == null) return null;
        
        if (visited == null) visited = new Map();
        if (visited.exists(node.id)) {
            trace('⚠️ [ShaderEditor] Cycle detected at node ${node.title}');
            return null;
        }
        visited.set(node.id, true);
        
        return switch (node.type) {
            // === ЛИСТОВЫЕ НОДЫ ===
            case "value/float":
                Reflect.field(node.properties, "value");
                
            case "value/vec3":
                {
                    x: Reflect.field(node.properties, "x"),
                    y: Reflect.field(node.properties, "y"),
                    z: Reflect.field(node.properties, "z")
                };
                
            case "value/color":
                {
                    x: Reflect.field(node.properties, "r"),
                    y: Reflect.field(node.properties, "g"),
                    z: Reflect.field(node.properties, "b")
                };
            
            // === MATH ОПЕРАЦИИ ===
            case "math/operation" | "math/add" | "math/subtract" | "math/multiply" | "math/divide" | "math/lerp":
                evaluateMathNode(node, visited);
            
            default:
                trace('⚠️ [ShaderEditor] Unsupported node type: ${node.type}');
                null;
        };
    }

    private function evaluateMathNode(node:Dynamic, visited:Map<Int, Bool>):Dynamic {
        var a = evaluateInput(node, 0, visited);
        var b = evaluateInput(node, 1, visited);
        
        if (a == null) a = 0;
        if (b == null) b = 0;
        
        var operation = Reflect.field(node.properties, "operation");
        
        // Определяем операцию по типу ноды или свойству
        if (operation == null) {
            operation = switch (node.type) {
                case "math/add": "add";
                case "math/subtract": "subtract";
                case "math/multiply": "multiply";
                case "math/divide": "divide";
                case "math/lerp": "lerp";
                default: "add";
            };
        }
        
        return switch (operation) {
            case "add":
                if (Std.is(a, Float) && Std.is(b, Float)) a + b;
                else if (isVec3(a) && isVec3(b)) { x: toVec3(a).x + toVec3(b).x, y: toVec3(a).y + toVec3(b).y, z: toVec3(a).z + toVec3(b).z };
                else if (isVec3(a) && Std.is(b, Float)) { x: toVec3(a).x + b, y: toVec3(a).y + b, z: toVec3(a).z + b };
                else null;
                
            case "subtract":
                if (Std.is(a, Float) && Std.is(b, Float)) a - b;
                else if (isVec3(a) && isVec3(b)) { x: toVec3(a).x - toVec3(b).x, y: toVec3(a).y - toVec3(b).y, z: toVec3(a).z - toVec3(b).z };
                else null;
                
            case "multiply":
                if (Std.is(a, Float) && Std.is(b, Float)) a * b;
                else if (isVec3(a) && Std.is(b, Float)) { x: toVec3(a).x * b, y: toVec3(a).y * b, z: toVec3(a).z * b };
                else if (isVec3(a) && isVec3(b)) { x: toVec3(a).x * toVec3(b).x, y: toVec3(a).y * toVec3(b).y, z: toVec3(a).z * toVec3(b).z };
                else null;
                
            case "divide":
                if (Std.is(a, Float) && Std.is(b, Float) && b != 0) a / b;
                else if (isVec3(a) && Std.is(b, Float) && b != 0) { x: toVec3(a).x / b, y: toVec3(a).y / b, z: toVec3(a).z / b };
                else null;
                
            case "lerp":
                // Упрощённо: (a + b) / 2
                if (Std.is(a, Float) && Std.is(b, Float)) (a + b) / 2;
                else null;
                
            default: null;
        };
    }
    function toVec3(param:Dynamic) {
        return cast(param,h3d.Vector);
    }
    /**
     * Вычисляет значение ВХОДА ноды, рекурсивно спускаясь по связи.
     */
    private function evaluateInput(node:Dynamic, inputSlot:Int, visited:Map<Int, Bool>):Dynamic {
        var link = node.getInputLink(inputSlot);
        if (link == null) return null;
        
        var sourceNode = graph.getNodeById(link.origin_id);
        if (sourceNode == null) return null;
        
        return evaluateNode(sourceNode, link.origin_slot, visited);
    }

    private function isVec3(v:Dynamic):Bool {
        return v != null && Reflect.hasField(v, "x") && Reflect.hasField(v, "y") && Reflect.hasField(v, "z");
    }

    private function initLiteGraph():Void {
        var container:js.html.Element = litegraphContainerRef.current;
        if (container == null) {
            trace("❌ [ShaderEditor] #litegraph-container not found!");
            return;
        }
        // ✅ Ждём, пока React завершит рендер и контейнер получит размеры
        haxe.Timer.delay(function() {
            // ✅ Получаем реальные размеры контейнера
            var rect = container.getBoundingClientRect();
            var w = Std.int(rect.width);
            var h = Std.int(rect.height);
            
            if (w < 100 || h < 100) {
                trace('⚠️ [ShaderEditor] Container too small: ${w}x${h}, retrying...');
                haxe.Timer.delay(function() initLiteGraph(), 100);
                return;
            }
            
            trace(' [ShaderEditor] Container size: ${w}x${h}');
            // Создаём canvas для редактора нод
            liteGraphCanvas = cast js.Browser.document.createElement("canvas");
            liteGraphCanvas.id = "shader-graph-canvas";
            liteGraphCanvas.width = w;
            liteGraphCanvas.height = h;
            //liteGraphCanvas.style.cssText = 'width:100%;height:100%;background:#1a1a1a;';
            

            container.appendChild(liteGraphCanvas);
            
            // ✅ Обработка клика по canvas для выделения ноды
            liteGraphCanvas.addEventListener("click", function(e:js.html.MouseEvent) {
                trace('🖱️ [ShaderEditor] Canvas clicked');
                
                // ✅ ПРАВИЛЬНАЯ ПРОВЕРКА: selected_nodes — объект
                if (graphCanvas.selected_nodes != null) {
                    var keys = Reflect.fields(graphCanvas.selected_nodes);
                    if (keys.length > 0) {
                        var firstKey = keys[0];
                        var selected = Reflect.field(graphCanvas.selected_nodes, firstKey);
                        trace('🎯 [ShaderEditor] Selected after click: ${selected.title}');
                        setState({
                            graph: graph,
                            selectedNode: selected
                        });
                    } else {
                        trace('🔍 [ShaderEditor] No selection after click');
                        setState({
                            graph: graph,
                            selectedNode: null
                        });
                    }
                } else {
                    trace('🔍 [ShaderEditor] selected_nodes is null');
                    setState({
                        graph: graph,
                        selectedNode: null
                    });
                }
            });
            // Создаём граф
            graph = new LGraph();
            
            // Создаём canvas для рендеринга графа
            graphCanvas = new LGraphCanvas(liteGraphCanvas, graph);
            graphCanvas.show_info = true;
            graphCanvas.allow_dragcanvas = true;
            graphCanvas.allow_zoomcanvas = true;
            // ✅ Явно задаём размер canvas для LGraphCanvas
            graphCanvas.resize(w, h);
            
            // ✅ Обработчики drag & drop из палитры
            setupDragAndDrop(container);
            // В initLiteGraph() добавьте обработчик выбора ноды:
            // ✅ Подписка на выбор ноды
            // ✅ ИСПРАВЛЕННАЯ ВЕРСИЯ: selected_nodes — это объект, а не массив!
            graphCanvas.onSelectionChange = function(nodes:Dynamic) {
                trace('🔍 [ShaderEditor] onSelectionChange called');
                trace('   nodes type: ${js.Lib.typeof(nodes)}');
                
                // ✅ ПРАВИЛЬНАЯ ПРОВЕРКА: nodes — это объект {id: node}
                if (nodes != null) {
                    var keys = Reflect.fields(nodes);
                    trace('   selected nodes count: ${keys.length}');
                    
                    if (keys.length > 0) {
                        // Берём первую выделенную ноду
                        var firstKey = keys[0];
                        var node = Reflect.field(nodes, firstKey);
                        trace('🎯 [ShaderEditor] Node selected: ${node.title} (id: ${node.id})');
                        
                        setState({
                            graph: graph,
                            selectedNode: node
                        });
                    } else {
                        trace('🔍 [ShaderEditor] No node selected');
                        setState({
                            graph: graph,
                            selectedNode: null
                        });
                    }
                } else {
                    trace('🔍 [ShaderEditor] nodes is null');
                    setState({
                        graph: graph,
                        selectedNode: null
                    });
                }
            };

            // ✅ ДОПОЛНИТЕЛЬНО: подписка на клик по ноде
            graphCanvas.onNodeMoved = function(node:LGraphNode) {
                trace('🖱️ [ShaderEditor] Node moved: ${node.title}');
                
                // ✅ ПРАВИЛЬНАЯ ПРОВЕРКА: selected_nodes — объект
                if (graphCanvas.selected_nodes != null) {
                    var keys = Reflect.fields(graphCanvas.selected_nodes);
                    if (keys.length > 0) {
                        var firstKey = keys[0];
                        var selected = Reflect.field(graphCanvas.selected_nodes, firstKey);
                        trace('🎯 [ShaderEditor] After move, selected: ${selected.title}');
                        setState({
                            graph: graph,
                            selectedNode: selected
                        });
                    }
                }
            };
            // Настраиваем
            registerShaderNodes();
            // Создаём обязательную ноду Material Output
            var outputNode = LiteGraph.createNode("material/output");
            if (outputNode != null) {
                outputNode.pos = [w / 2 - 100, h / 2 - 50];
                
                // ✅ ДОБАВЬ ЭТО: подписка на изменение связей
                untyped outputNode.onConnectionsChange = function(type:Int, slot:Int, isConnected:Bool, link_info:Dynamic, input_info:Dynamic) {
                    trace('🔗 [ShaderEditor] Material Output connection changed: slot $slot, connected: $isConnected');
                    scheduleRecompile();
                };
                
                graph.add(outputNode);
                trace("✅ Material Output node created");
            }
            // В методе initLiteGraph(), после создания graphCanvas:


            // ==========================
            // Запускаем граф
            graph.start();
            
            state = { graph: graph, selectedNode: null };
            trace("✅ [ShaderEditor] LiteGraph initialized");
        }, 100); // 100мс достаточно для React 17
    }
    /**
     * Обработка drag & drop из палитры нод в canvas графа
     */
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
                    
                    // ✅ ДОБАВЬ ЭТО: подписка на изменение связей ноды
                    untyped node.onConnectionsChange = function(type:Int, slot:Int, isConnected:Bool, link_info:Dynamic, input_info:Dynamic) {
                        trace('🔗 [ShaderEditor] Connection changed on node: ${node.title}, slot: $slot, connected: $isConnected');
                        scheduleRecompile();
                    };
                    
                    graph.add(node);
                    trace("✅ Node created: " + nodeType);
                }
            }
        });
    }
    private function registerShaderNodes():Void {
        // ✅ ПРАВИЛЬНЫЙ СПОСОБ: используем js.Syntax.code для создания JS-функций,
        // где `this` ссылается на экземпляр ноды, а не на ShaderEditorPanel
        
        // === Нода: Texture Sample ===
        var TextureSampleNode = js.Syntax.code("(function() { this.title = 'Texture Sample'; this.addInput('UV', 'vec2'); this.addOutput('RGBA', 'vec4'); this.properties = { texture: '' }; })");
        js.Syntax.code("TextureSampleNode.prototype.onExecute = function() { var uv = this.getInputData(0); if (uv == null) uv = [0, 0]; this.setOutputData(0, [1, 0, 0, 1]); }");
        LiteGraph.registerNodeType("texture/sample", TextureSampleNode);
        
        // === Нода: PBR Material ===
        var PBRMaterialNode = js.Syntax.code("(function() { this.title = 'PBR Material'; this.addInput('Albedo', 'vec3'); this.addInput('Normal', 'vec3'); this.addInput('Metallic', 'float'); this.addInput('Roughness', 'float'); this.addOutput('Color', 'vec3'); this.properties = { metallic: 0.5, roughness: 0.5 }; })");
        js.Syntax.code("PBRMaterialNode.prototype.onExecute = function() { var albedo = this.getInputData(0); if (albedo == null) albedo = [1, 1, 1]; this.setOutputData(0, albedo); }");
        LiteGraph.registerNodeType("material/pbr", PBRMaterialNode);
        
        // === Нода: Math Operation ===
        var MathNode = js.Syntax.code("(function() { this.title = 'Math'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'multiply' }; })");
        js.Syntax.code("MathNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; var result = 0; switch(this.properties.operation) { case 'add': result = a + b; break; case 'subtract': result = a - b; break; case 'multiply': result = a * b; break; case 'divide': result = b != 0 ? a / b : 0; break; case 'lerp': result = a + (b - a) * 0.5; break; } this.setOutputData(0, result); }");
        LiteGraph.registerNodeType("math/operation", MathNode);
        
        // === Нода: Float Value ===
        var FloatNode = js.Syntax.code("(function() { this.title = 'Float'; this.addOutput('Value', 'float'); this.properties = { value: 1.0 }; })");
        js.Syntax.code("FloatNode.prototype.onExecute = function() { this.setOutputData(0, this.properties.value); }");
        LiteGraph.registerNodeType("value/float", FloatNode);
        
        // === Нода: Vector3 ===
        var Vec3Node = js.Syntax.code("(function() { this.title = 'Vector3'; this.addOutput('Vector', 'vec3'); this.properties = { x: 0.0, y: 0.0, z: 0.0 }; })");
        js.Syntax.code("Vec3Node.prototype.onExecute = function() { this.setOutputData(0, [this.properties.x, this.properties.y, this.properties.z]); }");
        LiteGraph.registerNodeType("value/vec3", Vec3Node);
        
        // === Нода: Color ===
        var ColorNode = js.Syntax.code("(function() { 
            this.title = 'Color'; 
            this.addOutput('Color', 'vec3'); 
            this.properties = { r: 1.0, g: 1.0, b: 1.0 }; 
        })");
        js.Syntax.code("ColorNode.prototype.onExecute = function() { 
            this.setOutputData(0, [this.properties.r, this.properties.g, this.properties.b]); 
        }");
        LiteGraph.registerNodeType("value/color", ColorNode);

        // === Ноды: Math (отдельные для каждой операции) ===
        // === Нода: Add ===
        var AddNode = js.Syntax.code("
                (function() { 
                    this.title = 'Add'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'add' }; 
                })
            ");
        js.Syntax.code("AddNode.prototype.onExecute = function() { 
                    var a = this.getInputData(0); if (a == null) a = 0; 
                    var b = this.getInputData(1); if (b == null) b = 0; 
                    var result = a + b; 
                    this.setOutputData(0, result); 
                }");
        LiteGraph.registerNodeType("math/add", AddNode);

        // === Нода: Subtract ===
        var SubtractNode = js.Syntax.code("
                (function() { 
                    this.title = 'Subtract'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'subtract' }; 
                })
            ");
        js.Syntax.code("SubtractNode.prototype.onExecute = function() { 
                    var a = this.getInputData(0); if (a == null) a = 0; 
                    var b = this.getInputData(1); if (b == null) b = 0; 
                    var result = a - b; 
                    this.setOutputData(0, result); 
                }");
        LiteGraph.registerNodeType("math/subtract", SubtractNode);

        // === Нода: Multiply ===
        var MultiplyNode = js.Syntax.code("
                (function() { 
                    this.title = 'Multiply'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'multiply' }; 
                })
            ");
        js.Syntax.code("MultiplyNode.prototype.onExecute = function() { 
                    var a = this.getInputData(0); if (a == null) a = 0; 
                    var b = this.getInputData(1); if (b == null) b = 0; 
                    var result = a * b;
                    this.setOutputData(0, result); 
                }");
        LiteGraph.registerNodeType("math/multiply", MultiplyNode);    

        // === Нода: Divide ===
        var DivideNode = js.Syntax.code("
                (function() { 
                    this.title = 'Divide'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'divide' }; 
                })
            ");
        js.Syntax.code("DivideNode.prototype.onExecute = function() { 
                    var a = this.getInputData(0); if (a == null) a = 0; 
                    var b = this.getInputData(1); if (b == null) b = 0; 
                    var result = b != 0 ? a / b : 0; 
                    this.setOutputData(0, result); 
                }");
        LiteGraph.registerNodeType("math/divide", DivideNode);

        // === Нода: Lerp ===
        var LerpNode = js.Syntax.code("
                (function() { 
                    this.title = 'Lerp'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'lerp' }; 
                })
            ");
        js.Syntax.code("LerpNode.prototype.onExecute = function() { 
                    var a = this.getInputData(0); if (a == null) a = 0; 
                    var b = this.getInputData(1); if (b == null) b = 0; 
                    var result = a + (b - a) * 0.5; 
                    this.setOutputData(0, result); 
                }");
        LiteGraph.registerNodeType("math/lerp", LerpNode);    

        // === Нода: Material Output (ОБЯЗАТЕЛЬНАЯ) ===
        var OutputNode = js.Syntax.code("(function() { 
            this.title = 'Material Output'; 
            this.addInput('Albedo', 'vec3'); 
            this.addInput('Metallic', 'float'); 
            this.addInput('Roughness', 'float'); 
            this.addInput('Normal', 'vec3');
            this.addInput('Emissive', 'vec3');
            this.color = '#4a9';  // выделяем визуально
        })");
        LiteGraph.registerNodeType("material/output", OutputNode);
        trace("✅ [ShaderEditor] Shader nodes registered");
    }

    
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
                <button onClick={onCompile}>Compile</button>
                <button onClick={onSave}>Save</button>
                <button onClick={onExportHLSL}>Export HLSL</button>
                <div style={{flex: 1}}></div>
                <button onClick={onClearGraph}>Clear Graph</button>
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
    // Добавьте новый метод:
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
                    height: "400px",  // Было 300px
                    background: "#1a1a1a",  // Тёмный фон вместо чёрного
                    position: "relative",
                    border: "1px solid #333"
                }}>
                <div id="heaps-preview-container" 
                    style={{width: "100%", 
                    height: "100%", 
                    display: "block",
                    background: "#1a1a1a"}}>
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

    /*
    private function renderProperties():ReactElement {
        return jsx('
            <div style={{flex: 1, padding: "10px", background: "#2a2a2a", overflowY: "auto"}}>
                <h3 style={{margin: "0 0 10px 0", color: "#fff", fontSize: "14px"}}>
                    Properties
                </h3>
                {renderPropertiesContent()}
            </div>
        ');
    }
*/
    // В renderProperties() замените заглушку на:
    private function renderProperties(): ReactElement {
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

    // ✅ НОВЫЙ МЕТОД: вызывается при изменении свойства ноды
    private function onNodePropertyChanged(): Void {
        trace("🔄 [ShaderEditor] Node property changed, recompiling...");
        compileAndApply();
    }
    private function renderPropertiesContent():ReactElement {
        return jsx('
            <NodePropertiesPanel selectedNode={state.selectedNode} />
        ');
    }

    // Обработчики событий для toolbar
    private function onCompile():Void {
        trace("🔨 Compile shader graph");
        // TODO: компиляция графа в HXSL
    }

    private function onSave():Void {
        trace("💾 Save shader graph");
        // TODO: сохранение .shader файла
    }

    private function onExportHLSL():Void {
        trace("📤 Export HLSL");
        // TODO: экспорт в HLSL
    }

    private function onClearGraph():Void {
        if (graph != null) {
            graph.clear();
            trace("🧹 Graph cleared");
        }
    }
    
    override function componentWillUnmount():Void {
        if (graph != null) graph.stop();
        previewRenderer.dispose(); // ← освобождаем ресурсы engine layer
        //super.componentWillUnmount();
    }
}