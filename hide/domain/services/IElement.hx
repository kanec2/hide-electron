// hide/domain/services/IElement.hx

package hide.domain.services;

/**
 * Доменная абстракция DOM-элемента.
 * Реализуется в infrastructure (HtmlElement, CanvasElement, SkiaElement).
 */
interface IElement {
    /**
     * Устанавливает HTML-содержимое элемента.
     */
    function setInnerHtml(html:String):Void;

    /**
     * Добавляет дочерний элемент.
     */
    function appendChild(child:IElement):Void;

    /**
     * Добавляет обработчик события.
     */
    function addEventListener(event:String, handler:Dynamic->Void):Void;

    /**
     * Возвращает родительский элемент (если есть).
     */
    function getParent():Null<IElement>;
}