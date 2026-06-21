package hide.infrastructure.external.litegraph;

import infrastructure.external.litegraph.*;

class ShaderEditorPanel {
    private var graph:LGraph;
    private var graphCanvas:LGraphCanvas;
    
    public function new(canvas:js.html.CanvasElement) {
        // Создаём граф
        graph = new LGraph();
        
        // Создаём canvas для редактора
        graphCanvas = new LGraphCanvas(canvas, graph);
        
        // Настраиваем
        graphCanvas.show_info = true;
        graphCanvas.allow_dragcanvas = true;
        graphCanvas.allow_zoomcanvas = true;
        
        // Регистрируем ноды
        registerShaderNodes();
        
        // Запускаем
        graph.start();
    }
    
    private function registerShaderNodes():Void {
        // Регистрируем кастомные ноды для шейдеров
        var textureNode = {
            title: "Texture Sample",
            type: "texture/sample",
            properties: { texture: "" },
            inputs: [{name: "UV", type: "vec2"}],
            outputs: [{name: "RGBA", type: "vec4"}],
            onExecute: function() {
                // Логика ноды
            }
        };
        
        LiteGraph.registerNodeType("texture/sample", textureNode);
    }
}