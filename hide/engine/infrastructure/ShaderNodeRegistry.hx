package hide.engine.infrastructure;

import hide.infrastructure.external.litegraph.*;
import hx.injection.Service;
/**
    Реестр нод для Shader Editor.
    Отвечает за регистрацию всех типов нод в LiteGraph.
    Изолирован от UI и файловой системы — только регистрация нод.
*/
class ShaderNodeRegistry implements Service {
    private var isRegistered:Bool = false;
    public function new() {}

    /**
    Регистрирует все типы нод в LiteGraph.
    Вызывается один раз при инициализации ShaderEditorPanel.
    */
    public function registerAll():Void {
        if (isRegistered) return;
        
        registerInputOutputNodes();
        registerMathNodes();
        registerTextureNodes();
        registerPBRNodes();
        registerMaterialOutputNode();
        
        isRegistered = true;
        trace("✅ [ShaderNodeRegistry] All shader nodes registered");
    }

    /**
    Регистрирует ноды ввода/вывода (значения, цвета, векторы)
    */
    private function registerInputOutputNodes():Void {
        // Float Value
        var FloatNode = js.Syntax.code("(function() { this.title = 'Float'; this.addOutput('Value', 'float'); this.properties = { value: 1.0 }; })");
        js.Syntax.code("FloatNode.prototype.onExecute = function() { this.setOutputData(0, this.properties.value); }");
        LiteGraph.registerNodeType("value/float", FloatNode);
        
        // Vector3
        var Vec3Node = js.Syntax.code("(function() { this.title = 'Vector3'; this.addOutput('Vector', 'vec3'); this.properties = { x: 0.0, y: 0.0, z: 0.0 }; })");
        js.Syntax.code("Vec3Node.prototype.onExecute = function() { this.setOutputData(0, [this.properties.x, this.properties.y, this.properties.z]); }");
        LiteGraph.registerNodeType("value/vec3", Vec3Node);
        
        // Color
        var ColorNode = js.Syntax.code("(function() { this.title = 'Color'; this.addOutput('Color', 'vec3'); this.properties = { r: 1.0, g: 1.0, b: 1.0 }; })");
        js.Syntax.code("ColorNode.prototype.onExecute = function() { this.setOutputData(0, [this.properties.r, this.properties.g, this.properties.b]); }");
        LiteGraph.registerNodeType("value/color", ColorNode);
    }

    /**
    Регистрирует математические ноды (Add, Subtract, Multiply, Divide, Lerp)
    */
    private function registerMathNodes():Void {
        // Generic Math Operation
        var MathNode = js.Syntax.code("(function() { this.title = 'Math'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'multiply' }; })");
        js.Syntax.code("MathNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; var result = 0; switch(this.properties.operation) { case 'add': result = a + b; break; case 'subtract': result = a - b; break; case 'multiply': result = a * b; break; case 'divide': result = b != 0 ? a / b : 0; break; case 'lerp': result = a + (b - a) * 0.5; break; } this.setOutputData(0, result); }");
        LiteGraph.registerNodeType("math/operation", MathNode);
        
        // Add
        var AddNode = js.Syntax.code("(function() { this.title = 'Add'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'add' }; })");
        js.Syntax.code("AddNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; this.setOutputData(0, a + b); }");
        LiteGraph.registerNodeType("math/add", AddNode);
        
        // Subtract
        var SubtractNode = js.Syntax.code("(function() { this.title = 'Subtract'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'subtract' }; })");
        js.Syntax.code("SubtractNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; this.setOutputData(0, a - b); }");
        LiteGraph.registerNodeType("math/subtract", SubtractNode);
        
        // Multiply
        var MultiplyNode = js.Syntax.code("(function() { this.title = 'Multiply'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'multiply' }; })");
        js.Syntax.code("MultiplyNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; this.setOutputData(0, a * b); }");
        LiteGraph.registerNodeType("math/multiply", MultiplyNode);
        
        // Divide
        var DivideNode = js.Syntax.code("(function() { this.title = 'Divide'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'divide' }; })");
        js.Syntax.code("DivideNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; this.setOutputData(0, b != 0 ? a / b : 0); }");
        LiteGraph.registerNodeType("math/divide", DivideNode);
        
        // Lerp
        var LerpNode = js.Syntax.code("(function() { this.title = 'Lerp'; this.addInput('A', 'float'); this.addInput('B', 'float'); this.addOutput('Result', 'float'); this.properties = { operation: 'lerp' }; })");
        js.Syntax.code("LerpNode.prototype.onExecute = function() { var a = this.getInputData(0); if (a == null) a = 0; var b = this.getInputData(1); if (b == null) b = 0; this.setOutputData(0, a + (b - a) * 0.5); }");
        LiteGraph.registerNodeType("math/lerp", LerpNode);
    }

    /**
    Регистрирует ноды для работы с текстурами
    */
    private function registerTextureNodes():Void {
        // Texture Sample (с кнопкой Browse)
        var TextureSampleNode = js.Syntax.code("
            (function() { 
                this.title = 'Texture Sample'; 
                this.addInput('UV', 'vec2'); 
                this.addOutput('RGBA', 'vec4'); 
                this.properties = { texture: '' };
                var that = this;
                this.addWidget('button', 'Browse', null, function() {
                    if (window.__browseShaderTexture) {
                        window.__browseShaderTexture(that);
                    }
                });
                this.addWidget('string', 'texture', '', function(v) {
                    that.properties.texture = v;
                });
            })
        ");
        js.Syntax.code("TextureSampleNode.prototype.onExecute = function() { var uv = this.getInputData(0); if (uv == null) uv = [0, 0]; this.setOutputData(0, [1, 1, 1, 1]); }");
        LiteGraph.registerNodeType("texture/sample", TextureSampleNode);
        
        // Normal Map
        var NormalMapNode = js.Syntax.code("
            (function() { 
                this.title = 'Normal Map'; 
                this.addInput('Normal', 'vec3');
                this.addInput('Strength', 'float');
                this.addOutput('Normal', 'vec3');
                this.properties = { strength: 1.0 };
                var that = this;
                this.addWidget('number', 'strength', 1.0, function(v) {
                    that.properties.strength = v;
                }, { min: 0, max: 2, step: 0.1 });
            })
        ");
        js.Syntax.code("NormalMapNode.prototype.onExecute = function() { 
            var normal = this.getInputData(0); 
            if (normal == null) normal = [0, 0, 1];
            var strength = this.properties.strength;
            this.setOutputData(0, [normal[0] * strength, normal[1] * strength, normal[2]]);
        }");
        LiteGraph.registerNodeType("texture/normal", NormalMapNode);
    }

    /**
    Регистрирует PBR-ноды (заглушки для будущего расширения)
    */
    private function registerPBRNodes():Void {
        // PBR Material
        var PBRMaterialNode = js.Syntax.code("(function() { this.title = 'PBR Material'; this.addInput('Albedo', 'vec3'); this.addInput('Normal', 'vec3'); this.addInput('Metallic', 'float'); this.addInput('Roughness', 'float'); this.addOutput('Color', 'vec3'); this.properties = { metallic: 0.5, roughness: 0.5 }; })");
        js.Syntax.code("PBRMaterialNode.prototype.onExecute = function() { var albedo = this.getInputData(0); if (albedo == null) albedo = [1, 1, 1]; this.setOutputData(0, albedo); }");
        LiteGraph.registerNodeType("material/pbr", PBRMaterialNode);
    }

    /**
    Регистрирует обязательную ноду Material Output
    */
    private function registerMaterialOutputNode():Void {
        var OutputNode = js.Syntax.code("(function() { 
            this.title = 'Material Output'; 
            this.addInput('Albedo', 'vec3,vec4');
            this.addInput('Metallic', 'float'); 
            this.addInput('Roughness', 'float'); 
            this.addInput('Normal', 'vec3');
            this.addInput('Emissive', 'vec3');
            this.color = '#4a9';
        })");
        LiteGraph.registerNodeType("material/output", OutputNode);
    }

    /**
        Создаёт ноду Material Output с подпиской на изменение связей.
        Вызывается при создании нового графа.

        @param graph LiteGraph граф
        @param onConnectionChange Callback при изменении связи
        @return Созданная нода или null
    */
    public function createMaterialOutput(graph:LGraph, onConnectionChange:Dynamic->Void, canvasWidth:Int, canvasHeight:Int):Null<Dynamic> {
        var outputNode = LiteGraph.createNode("material/output");
        if (outputNode != null) {
            outputNode.pos = [canvasWidth / 2 - 100, canvasHeight / 2 - 50];
            
            untyped outputNode.onConnectionsChange = function(type:Int, slot:Int, isConnected:Bool, link_info:Dynamic, input_info:Dynamic) {
                if (onConnectionChange != null) {
                    onConnectionChange(outputNode);
                }
            };
            
            graph.add(outputNode);
        }
        return outputNode;
    }
}