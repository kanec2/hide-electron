// hide/domain/services/ILayoutEngine.hx

package hide.domain.services;

import hide.domain.valueobjects.LayoutState;
import hide.domain.valueobjects.DisplayPosition;

import hide.shared.types.IEventBus; // ← ВАЖНО: из shared, а не domain
/**
 * Доменный интерфейс для управления layout'ом.
 * НЕ зависит от GoldenLayout, HTML или платформы.
 */
interface ILayoutEngine {
    /**
     * Инициализирует layout из сохранённого состояния.
     */
    function init(state:LayoutState):Void;

    /**
     * Открывает компонент в указанной позиции.
     */
    function open(componentName:String, state:Dynamic, ?position:DisplayPosition):Void;

    /**
     * Сохраняет текущее состояние layout'а.
     */
    function save():LayoutState;

    /**
     * Закрытая вкладка → reopenLastClosed()
     */
    function reopenLastClosed():Void;

    /**
     * Закрывает текущий layout и освобождает ресурсы.
     */
    function dispose():Void;

    /**
     * Подписка на событие изменения layout'а.
     * Используется в `LayoutService`, чтобы обновлять UI.
     */
    function onLayoutChanged(callback:Void->Void):Void;
}