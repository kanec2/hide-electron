// hide/shared/types/IEventBus.hx

package hide.shared.types;

/**
 * Общий интерфейс для EventBus.
 * Используется во всех слоях (domain, application, presentation).
 * Предоставляет публикацию и подписку на события.
 */
interface IEventBus {
    /**
     * Подписка на событие типа T.
     * Возвращает функцию-отписку.
     */
    public function subscribe<T>(handler:T->Void):Void->Void;

    /**
     * Публикация события.
     */
    public function publish<T>(event:T):Void;
}