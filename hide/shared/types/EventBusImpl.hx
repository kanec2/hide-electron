package hide.shared.types;

import tink.core.*;
using tink.CoreApi;

class EventBusImpl implements IEventBus {
    private var handlers: Map<String, Array<Dynamic->Void>> = [];

    public function new() {}

    public function subscribe<T>(eventClass: Class<T>, handler: T->Void): CallbackLink {
        var typeName = Type.getClassName(eventClass);
        var list = handlers.get(typeName);
        if (list == null) {
            list = [];
            handlers.set(typeName, list);
        }
        
        var typedHandler: Dynamic->Void = cast handler;
        list.push(typedHandler);
        
        // Возвращаем функцию отписки, которая автоматически приводится к CallbackLink (Void->Void)
        return function() {
            list.remove(typedHandler);
        };
    }

    public function publish<T>(eventClass: Class<T>, event: T): Void {
        var typeName = Type.getClassName(eventClass);
        var list = handlers.get(typeName);
        if (list != null) {
            // Копируем массив, чтобы отписка во время итерации не сломала цикл
            var snapshot = list.copy();
            for (h in snapshot) {
                h(cast event);
            }
        }
    }
}