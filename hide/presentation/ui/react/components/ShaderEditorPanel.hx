// hide/presentation/ui/react/components/ShaderEditorPanel.hx
package hide.presentation.ui.react.components;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.infrastructure.external.litegraph.*;

typedef ShaderEditorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef ShaderEditorState = {
    var graph: Dynamic;
}

class ShaderEditorPanel extends BaseReactComponent<ShaderEditorProps, ShaderEditorState> {
    private var liteGraphCanvas:js.html.CanvasElement;
    private var graph:LGraph;
    private var graphCanvas:LGraphCanvas;
    private var previewRenderer:ShaderPreviewRenderer; // ← инжектируем
    
    public function new() {
        super();
        // ✅ Получаем рендерер из DI, а не создаём h3d.Engine вручную!
        previewRenderer = UseService.shaderPreviewRenderer();
        state = { graph: null };
    }
    
    override function componentDidMount():Void {
        initLiteGraph();
        // ✅ Передаём DOM-контейнер в engine layer
        var previewContainer = js.Browser.document.getElementById("heaps-preview-container");
        previewRenderer.init(previewContainer);
        
        registerShaderNodes();
    }
    
    private function initLiteGraph():Void {
        // Создаём canvas для редактора нод
        liteGraphCanvas = cast js.Browser.document.createElement("canvas");
        liteGraphCanvas.id = "shader-graph-canvas";
        liteGraphCanvas.width = 800;
        liteGraphCanvas.height = 600;
        liteGraphCanvas.style.cssText = 'width:100%;height:100%;background:#1a1a1a;';
        
        var container = js.Browser.document.getElementById("litegraph-container");
        if (container != null) {
            container.appendChild(liteGraphCanvas);
            
            // Создаём граф
            graph = new LGraph();
            
            // Создаём canvas для рендеринга графа
            graphCanvas = new LGraphCanvas(liteGraphCanvas, graph);
            
            // Настраиваем
            graphCanvas.show_info = true;
            graphCanvas.allow_dragcanvas = true;
            graphCanvas.allow_zoomcanvas = true;
            
            // Запускаем граф
            graph.start();
            
            state = { graph: graph };
        }
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
                {renderNodeEditor()}
                {renderRightPanel()}
            </div>
        ');
    }

    private function renderNodeEditor():ReactElement {
        return jsx('
            <div id="litegraph-container" 
                style={{flex: 1, position: "relative", background: "#1a1a1a"}}>
            </div>
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
            <div style={{height: "300px", background: "#000", position: "relative"}}>
                <div id="heaps-preview-container" 
                    style={{width: "100%", height: "100%"}}>
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
                {renderPropertiesContent()}
            </div>
        ');
    }

    private function renderPropertiesContent():ReactElement {
        // Позже здесь будет рендеринг свойств выбранной ноды
        return jsx('
            <div style={{color: "#888", fontSize: "12px"}}>
                Select a node to edit properties
            </div>
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
        super.componentWillUnmount();
    }
}