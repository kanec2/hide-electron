package hide.infrastructure.external.arborist;

typedef MoveHandlerArgs<T> = {
    var dragIds:Array<String>;
    var parentId:Null<String>;
    var index:Int;
    var dragNodes:Array<NodeApi<T>>;
    var parentNode:Null<NodeApi<T>>;
}