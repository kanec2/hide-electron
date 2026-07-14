// hide/infrastructure/external/ReactArborist.hx
package hide.infrastructure.external.arborist;

typedef ArboristNode = {
    var id:String;
    var name:String;
    var ?isLeaf:Bool;
    var ?children:Array<ArboristNode>; // Теперь это массив
    var ?isLoading:Bool;
    var ?isLoaded:Bool;
    var ?path:String;
    var ?relativePath:String;
    var ?extension:Null<String>;
}