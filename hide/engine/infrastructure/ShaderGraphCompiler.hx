// engine/infrastructure/ShaderGraphCompiler.hx
package hide.engine.infrastructure;

import hide.infrastructure.external.litegraph.*;
import hx.injection.Service;
/**
    Компилятор графа нод в ShaderData.
    Отвечает за рекурсивный обход графа и вычисление значений.
*/
class ShaderGraphCompiler implements Service {
    public function new() {}
    /**
     * Компилирует граф в ShaderData.
     * Ищет ноду Material Output и обходит граф от неё.
     */
    public function compile(graph:LGraph):ShaderData {
        var result:ShaderData = {
            albedo: new h3d.Vector(0.8, 0.8, 0.8),
            metallic: 0.0,
            roughness: 0.5,
            normal: new h3d.Vector(0, 0, 1),
            emissive: new h3d.Vector(0, 0, 0),
            hasTexture: false,
            texturePath: null
        };
        
        if (graph == null) {
            trace("⚠️ [Compiler] Graph is null");
            return result;
        }
        
        var nodes:Dynamic = untyped graph._nodes;
        if (nodes == null) {
            trace("⚠️ [Compiler] graph._nodes is null");
            return result;
        }
        
        var nodesArray:Array<Dynamic> = cast nodes;
        
        // Ищем Material Output
        var outputNode:Dynamic = null;
        for (node in nodesArray) {
            if (node.type == "material/output") {
                outputNode = node;
                break;
            }
        }
        
        if (outputNode == null) {
            trace("⚠️ [Compiler] No Material Output found");
            return result;
        }
        
        // Вычисляем все PBR-параметры
        var albedo = evaluateInput(outputNode, 0, new Map());
        var metallic = evaluateInput(outputNode, 1, new Map());
        var roughness = evaluateInput(outputNode, 2, new Map());
        var normal = evaluateInput(outputNode, 3, new Map());
        var emissive = evaluateInput(outputNode, 4, new Map());
        
        result.albedo = convertToVector(albedo, new h3d.Vector(0.8, 0.8, 0.8));
        result.metallic = convertToFloat(metallic, 0.0);
        result.roughness = convertToFloat(roughness, 0.5);
        result.normal = convertToVector(normal, new h3d.Vector(0, 0, 1));
        result.emissive = convertToVector(emissive, new h3d.Vector(0, 0, 0));
        
        return result;
    }

    /**
     * Рекурсивно вычисляет значение выхода ноды.
     */
    private function evaluateNode(node:Dynamic, outputSlot:Int, visited:Map<Int, Bool>):Dynamic {
        if (node == null) return null;
        
        if (visited == null) visited = new Map();
        if (visited.exists(node.id)) {
            trace('⚠️ [Compiler] Cycle detected at node ${node.title}');
            return null;
        }
        visited.set(node.id, true);
        
        return switch (node.type) {
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
                
            case "texture/normal":
                var inputNormal = evaluateInput(node, 0, visited);
                var strength = Reflect.field(node.properties, "strength");
                if (strength == null) strength = 1.0;
                
                if (inputNormal == null) {
                    inputNormal = { x: 0.0, y: 0.0, z: 1.0 };
                }
                
                var nx = isVec3(inputNormal) ? inputNormal.x : 0.0;
                var ny = isVec3(inputNormal) ? inputNormal.y : 0.0;
                var nz = isVec3(inputNormal) ? inputNormal.z : 1.0;
                
                {
                    x: nx * strength,
                    y: ny * strength,
                    z: nz
                };
                
            case "texture/sample":
                var texPath = Reflect.field(node.properties, "texture");
                if (texPath != null && texPath != "") {
                    // Возвращаем путь к текстуре для обработки в ShaderEditorPanel
                    { texturePath: texPath };
                }
                { x: 1.0, y: 1.0, z: 1.0 };
                
            case "math/operation" | "math/add" | "math/subtract" | "math/multiply" | "math/divide" | "math/lerp":
                evaluateMathNode(node, visited);
                
            default:
                trace('⚠️ [Compiler] Unsupported node type: ${node.type}');
                null;
        };
    }

    /**
     * Вычисляет математическую ноду.
     */
    private function evaluateMathNode(node:Dynamic, visited:Map<Int, Bool>):Dynamic {
        var a = evaluateInput(node, 0, visited);
        var b = evaluateInput(node, 1, visited);
        
        if (a == null) a = 0;
        if (b == null) b = 0;
        
        var operation = Reflect.field(node.properties, "operation");
        
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
                if (Std.is(a, Float) && Std.is(b, Float)) (a + b) / 2;
                else null;
                
            default: null;
        };
    }

    /**
     * Вычисляет значение входа ноды.
     */
    private function evaluateInput(node:Dynamic, inputSlot:Int, visited:Map<Int, Bool>):Dynamic {
        var link = node.getInputLink(inputSlot);
        if (link == null) return null;
        
        var sourceNode = node.graph.getNodeById(link.origin_id);
        if (sourceNode == null) return null;
        
        return evaluateNode(sourceNode, link.origin_slot, visited);
    }

    /**
     * Конвертирует Dynamic в h3d.Vector.
     */
    private function convertToVector(value:Dynamic, defaultValue:h3d.Vector):h3d.Vector {
        if (value == null) return defaultValue;
        
        if (isVec3(value)) {
            return new h3d.Vector(value.x, value.y, value.z);
        }
        
        return defaultValue;
    }

    /**
     * Конвертирует Dynamic в Float.
     */
    private function convertToFloat(value:Dynamic, defaultValue:Float):Float {
        if (value == null) return defaultValue;
        
        if (Std.is(value, Float)) return value;
        
        return defaultValue;
    }

    private function toVec3(param:Dynamic):h3d.Vector {
        return cast(param, h3d.Vector);
    }

    private function isVec3(v:Dynamic):Bool {
        return v != null && Reflect.hasField(v, "x") && Reflect.hasField(v, "y") && Reflect.hasField(v, "z");
    }
}