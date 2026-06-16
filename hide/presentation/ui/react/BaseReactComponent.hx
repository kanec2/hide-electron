package hide.presentation.ui.react;

import react.ReactComponent;
import hide.shared.types.IEventBus;
import tink.core.*;
import react.ReactMacro.jsx;
using tink.CoreApi;
/**
 * Базовый React-компонент с интеграцией в Haxe-сервисы.
 * Автоматически отписывается от событий при unmount.
 */
class BaseReactComponent<P, S> extends ReactComponentOfPropsAndState<P, S> {
    private var subscriptions:Array<CallbackLink> = [];
    
    /**
     * Подписывает компонент на событие EventBus.
     * Автоматически отписывается при unmount.
     */
    private function subscribe<T>(eventBus:IEventBus, eventClass:Class<T>, handler:T->Void):Void {
        var link = eventBus.subscribe(eventClass, handler);
        subscriptions.push(link);
    }
    // ✅ ДОБАВЛЕНО: Базовый render, чтобы удовлетворить компилятор
    override function render():ReactElement {
        return jsx('<div></div>');
    }
    override function componentWillUnmount():Void {
        // Отписываемся от всех событий
        for (link in subscriptions) {
            link.cancel();
        }
        subscriptions = [];
        super.componentWillUnmount();
    }
}