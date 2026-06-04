// hide/infrastructure/external/HtmlElement.hx

package hide.infrastructure.external;

import hide.domain.services.IElement;
import js.html.Element;

class HtmlElement implements IElement {
    private var element:Element;

    public function new(element:Element) {
        this.element = element;
    }

    public function setInnerHtml(html:String):Void {
        element.innerHtml = html;
    }

    public function appendChild(child:IElement):Void {
        element.appendChild(cast child.element);
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