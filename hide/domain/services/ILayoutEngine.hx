// hide/domain/services/ILayoutEngine.hx

package hide.domain.services;

import hide.domain.valueobjects.LayoutState;
import hide.domain.valueobjects.DisplayPosition;
import hx.injection.Service;
/**
 * Доменный интерфейс для управления layout'ом.
 * НЕ зависит от GoldenLayout, HTML или платформы.
 */
interface ILayoutEngine extends Service{
    // ✅ ДОБАВИТЬ ЭТУ СТРОКУ
    function setContainer(el:Dynamic):Void;
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
     * Закрывает текущий layout и освобождает ресурсы.
     */
    function dispose():Void;

    /**
     * Подписка на событие изменения layout'а.
     * Используется в `LayoutService`, чтобы обновлять UI.
     */
    function onLayoutChanged(callback:Void->Void):Void;

    /**
     * Регистрация view-фабрик (через IElement)
     */
    function registerView(type:String, factory:IViewFactory):Void;


}