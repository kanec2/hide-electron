// hide/shared/types/EventBusImpl.hx
package hide.shared.types;
import tink.core.Signal;
import tink.core.CallbackLink;
class EventBusImpl implements IEventBus {
    // Храним сигналы по имени класса. Используем Dynamic, так как дженерики в Haxe стираются в рантайме.
    private var signals:Map<String, Signal<Dynamic>> = [];

    public function new() {}

    public function subscribe<T>(eventClass:Class<T>, handler:T->Void):CallbackLink {
        var typeName = Type.getClassName(eventClass);
        
        if (!signals.exists(typeName)) {
            // Создаем новый сигнал для этого типа события
            signals.set(typeName, cast new Signal<Dynamic>());
        }

        var signal = signals.get(typeName);
        // Приводим handler к Dynamic->Void, чтобы Signal мог его принять
        return signal.handle(cast handler);
    }

    public function publish<T>(eventClass:Class<T>, event:T):Void {
        var typeName = Type.getClassName(eventClass);
        
        if (signals.exists(typeName)) {
            var signal = signals.get(typeName);
            signal.trigger(cast event);
        }
    }
}