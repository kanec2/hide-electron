package hide.engine.infrastructure;

typedef ShaderGraphData = {
    var version:String;
    var createdAt:String;
    var modifiedAt:String;
    var graph:Dynamic;  // LiteGraph serialize() output
    var ?viewport:{ x:Float, y:Float, scale:Float };
}