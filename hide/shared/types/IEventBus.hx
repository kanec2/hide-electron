// hide/shared/types/IEventBus.hx

package hide.shared.types;
import tink.core.CallbackLink;
/**
 * Общий интерфейс для EventBus.
 * Используется во всех слоях (domain, application, presentation).
 * Предоставляет публикацию и подписку на события.
 */
interface IEventBus {
    /**
     * Подписка на событие.
     * @param eventClass Класс события (нужен для определения типа в рантайме)
     * @param handler Функция-обработчик
     * @return Ссылка для отписки (вызовите .cancel() для удаления слушателя)
     */
    function subscribe<T>(eventClass:Class<T>, handler:T->Void):CallbackLink;

    /**
     * Публикация события.
     */
    function publish<T>(eventClass:Class<T>, event:T):Void;
}