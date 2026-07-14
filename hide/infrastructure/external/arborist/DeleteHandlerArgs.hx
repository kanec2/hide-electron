package hide.infrastructure.external.arborist;

typedef DeleteHandlerArgs<T> = {
    var ids:Array<String>;
    var nodes:Array<NodeApi<T>>;
}