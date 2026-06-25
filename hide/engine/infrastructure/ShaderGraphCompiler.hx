// engine/infrastructure/ShaderGraphCompiler.hx
package hide.engine.infrastructure;

import hide.infrastructure.external.litegraph.*;



class ShaderGraphCompiler {
    
    /**
     * Компилирует LiteGraph граф в ShaderData.
     * Ищет ноду "material/output" и обходит граф от неё.
     */
    public static function compile(graph:LGraph):ShaderData {
        var result:ShaderData = {
            albedo: new h3d.Vector(0.8, 0.8, 0.8),
            metallic: 0.0,
            roughness: 0.5,
            normal: new h3d.Vector(0, 0, 1),
            emissive: new h3d.Vector(0, 0, 0),
            hasTexture: false,
            texturePath: null
        };
        
        if (graph == null || graph.nodes == null) return result;
        
        // 1. Ищем выходную ноду (Material Output)
        var outputNode:LGraphNode = null;
        for (node in graph.nodes) {
            if (node.type == "material/output") {
                outputNode = node;
                break;
            }
        }
        
        if (outputNode == null) {
            trace("⚠️ [Compiler] No 'material/output' node found");
            return result;
        }
        
        // 2. Обходим граф от выхода ко входам
        trace("🔍 [Compiler] Starting graph traversal from output node");
        traverseNode(outputNode, graph, result);
        
        return result;
    }
    
    /**
     * Рекурсивный обход графа.
     * Для каждого входа ноды смотрим, что к нему подключено.
     */
    private static function traverseNode(
        node:LGraphNode, 
        graph:LGraph, 
        result:ShaderData,
        ?visited:Map<Int, Bool>
    ):Dynamic {
        if (visited == null) visited = new Map();
        if (visited.exists(node.id)) return null;
        visited.set(node.id, true);
        
        trace('  🔎 Visiting node: ${node.title} (type: ${node.type})');
        
        // Обрабатываем саму ноду (её свойства)
        processNode(node, result);
        
        // Рекурсивно обходим подключенные ноды
        if (node.inputs != null) {
            for (i in 0...node.inputs.length) {
                var link:LGraphLink = node.getInputLink(i);
                if (link != null) {
                    var originNode = graph.getNodeById(link.origin_id);
                    if (originNode != null) {
                        var inputData = traverseNode(originNode, graph, result, visited);
                        // Передаём данные от входа в текущую ноду
                        connectNodes(originNode, node, i, inputData, result);
                    }
                }
            }
        }
        
        return getNodeOutput(node, result);
    }
    
    /**
     * Обрабатывает свойства конкретной ноды.
     */
    private static function processNode(node:LGraphNode, result:ShaderData):Void {
        switch (node.type) {
            case "value/float":
                // Значение берётся из properties.value
                // (будет использовано, когда подключится к metallic/roughness)
                
            case "value/vec3":
                // Аналогично
                
            case "material/output":
                // Выходная нода — просто триггер для обхода
                
            case "texture/sample":
                var texPath = node.properties != null ? node.properties.texture : null;
                if (texPath != null && texPath != "") {
                    result.hasTexture = true;
                    result.texturePath = texPath;
                }
                
            default:
        }
    }
    
    /**
     * Возвращает выходные данные ноды.
     */
    private static function getNodeOutput(node:LGraphNode, result:ShaderData):Dynamic {
        return switch (node.type) {
            case "value/float": 
                node.properties != null ? node.properties.value : 0.0;
            case "value/vec3":
                if (node.properties != null) {
                    new h3d.Vector(
                        node.properties.x, 
                        node.properties.y, 
                        node.properties.z
                    );
                } else new h3d.Vector(0, 0, 0);
            case "texture/sample":
                // Возвращаем "цвет текстуры" (пока заглушка)
                new h3d.Vector(1, 1, 1);
            default: null;
        }
    }
    
    /**
     * Соединяет выход одной ноды со входом другой.
     * Здесь определяется семантика: "float → metallic" значит 
     * "значение этого float'а становится параметром metallic".
     */
    private static function connectNodes(
        origin:LGraphNode, 
        target:LGraphNode, 
        inputSlot:Int, 
        inputData:Dynamic, 
        result:ShaderData
    ):Void {
        if (inputData == null) return;
        
        var inputName = target.inputs != null && target.inputs.length > inputSlot 
            ? target.inputs[inputSlot].name 
            : "";
        
        // Определяем, к какому параметру материала относится этот вход
        if (target.type == "material/output") {
/*            switch (inputName) {
                case "Albedo":
                    if (Std.is(inputData, h3d.Vector)) result.albedo = inputData;
                case "Metallic":
                    if (Std.is(inputData, Float)) result.metallic = inputData;
                case "Roughness":
                    if (Std.is(inputData, Float)) result.roughness = inputData;
                case "Normal":
                    if (Std.is(inputData, h3d.Vector)) result.normal = inputData;
                case "Emissive":
                    if (Std.is(inputData, h3d.Vector)) result.emissive = inputData;
            }*/
        }
        // Для других нод (math, lerp и т.д.) — своя логика
    }
}