package hide.infrastructure.external;

import hide.domain.services.IElement;
import js.html.Element;

class HtmlElement implements IElement {
    private var element:Element;
    
    public function new(element:Dynamic) {
        // GoldenLayout возвращает JQuery, нужно получить raw element
        if (Std.is(element, Element)) {
            this.element = cast element;
        } else if (Reflect.hasField(element, "get")) {
            // Это JQuery
            this.element = cast element.get(0);
        } else {
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