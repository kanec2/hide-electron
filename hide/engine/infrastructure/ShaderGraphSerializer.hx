package hide.engine.infrastructure;

import hide.infrastructure.external.litegraph.LGraph;
import hide.infrastructure.external.litegraph.LGraphCanvas;

class ShaderGraphSerializer {
    public static var VERSION = "1.0";
    
    /**
     * Сериализует граф в JSON
     */
    public static function serialize(graph:LGraph, ?graphCanvas:LGraphCanvas):ShaderGraphData {
        return {
            version: VERSION,
            createdAt: Date.now().toString(),
            modifiedAt: Date.now().toString(),
            graph: graph.serialize(),
            viewport: graphCanvas != null ? {
                x: graphCanvas.ds.offset[0],
                y: graphCanvas.ds.offset[1],
                scale: graphCanvas.ds.scale
            } : null
        };
    }
    
    /**
     * Десериализует JSON обратно в граф
     */
    public static function deserialize(data:ShaderGraphData, graph:LGraph, ?graphCanvas:LGraphCanvas):Void {
        if (data.version != VERSION) {
            trace('⚠️ [Serializer] Version mismatch: expected $VERSION, got ${data.version}');
        }
        
        graph.configure(data.graph);
        
        // Восстанавливаем позицию камеры
        if (data.viewport != null && graphCanvas != null) {
            graphCanvas.ds.offset[0] = data.viewport.x;
            graphCanvas.ds.offset[1] = data.viewport.y;
            graphCanvas.ds.scale = data.viewport.scale;
            graphCanvas.setDirty(true, true);
        }
    }
    
    /**
     * Конвертирует в JSON-строку
     */
    public static function toJson(data:ShaderGraphData):String {
        return haxe.Json.stringify(data, "\t");
    }
    
    /**
     * Парсит JSON-строку
     */
    public static function fromJson(json:String):ShaderGraphData {
        return haxe.Json.parse(json);
    }
}