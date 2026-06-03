// hide/shared/types/EventBusImpl.hx

package hide.shared.types;

class EventBusImpl implements IEventBus {
    private var handlers:Map<String, Array<Dynamic->Void>> = [];

    public function subscribe<T>(handler:T->Void):Void->Void {
        var typeName = Type.getClassName(Type.getClass(handler));
        if (handlers[typeName] == null) handlers[typeName] = [];
        handlers[typeName].push(handler);

        return function() {
            handlers[typeName].remove(handler);
            if (handlers[typeName].length == 0) handlers.remove(typeName);
        };
    }

    public function publish<T>(event:T):Void {
        var typeName = Type.getClassName(Type.getClass(event));
        for (h in handlers[typeName] ?? []) {
            h(event);
        }
    }
}