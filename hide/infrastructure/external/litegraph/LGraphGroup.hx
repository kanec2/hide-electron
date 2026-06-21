// infrastructure/external/litegraph/LGraphGroup.hx
package hide.infrastructure.external.litegraph;

extern class LGraphGroup {
    var title:String;
    var pos:Array<Float>;
    var size:Array<Float>;
    var color:String;
    var font:String;
    var _bounding:Array<Float>;
    var _nodes:Array<LGraphNode>;
    var graph:LGraph;
    var flags:Dynamic;
    var id:Int;
    
    function new();
    
    function move(deltaX:Float, deltaY:Float):Void;
    function recomputeInsideNodes():Void;
    function addNode(node:LGraphNode):Void;
    function removeNode(node:LGraphNode):Void;
    function isPointInside(x:Float, y:Float):Bool;
    function getBounding():Array<Float>;
    function configure(o:Dynamic):Void;
    function serialize():Dynamic;
}