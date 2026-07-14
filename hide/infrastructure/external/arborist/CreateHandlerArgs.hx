package hide.infrastructure.external.arborist;

typedef CreateHandlerArgs = {
    var parentId:String;
    var index:Int;
    var type:String; // "folder" или "internal"
}