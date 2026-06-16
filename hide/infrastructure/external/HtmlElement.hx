package hide.infrastructure.external;

import hide.domain.services.IElement;
import js.html.Element;

class HtmlElement implements IElement {
    private var element:Element;
    
    public function new(element:Dynamic) {
        // GoldenLayout возвращает JQuery, нужно получить raw element
        if (element == null) {
            // Fallback на случай, если передан null
            this.element = js.Browser.document.createElement("div");
        } else if (element.nodeType != null) {
            // Это уже "голый" DOM-элемент (наиболее вероятный сценарий в GL v2/v3)
            this.element = cast element;
        } else if (element.length != null && element[0] != null) {
            // Это jQuery-подобный объект (массив с элементами)
            this.element = cast element[0];
        } else if (Reflect.hasField(element, "get") && Reflect.isFunction(element.get)) {
            // У объекта есть метод .get() (классический jQuery)
            this.element = cast element.get(0);
        } else {
            // Попытка прямого каста как последняя надеждa
            this.element = cast element;
        }
    }

    public function setInnerHtml(html:String):Void {
        element.innerHTML = html;  // ← innerHTML (заглавные)
    }

    public function appendChild(child:IElement):Void {
        var childHtml:HtmlElement = cast child;  // ← каст к HtmlElement
        element.appendChild(childHtml.element);
    }

    public function addEventListener(event:String, handler:Dynamic->Void):Void {
        element.addEventListener(event, handler);
    }

    public function getParent():Null<IElement> {
        if (element.parentElement == null) return null;
        return new HtmlElement(element.parentElement);
    }

    public function getElement():Element {
        return element;
    }
}