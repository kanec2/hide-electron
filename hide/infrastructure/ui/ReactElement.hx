package hide.infrastructure.ui;

import hide.domain.services.IElement;
import js.html.Element;
import react.React;
import react.ReactComponent;

/**
 * React-ориентированная реализация IElement.
 * Вместо setInnerHtml использует React-рендеринг.
 */
class ReactElement implements IElement {
    private var element:Element;
    private var root:ReactRoot;
    
    public function new(element:Element) {
        this.element = element;
        this.root = new ReactRoot(element);
    }
    
    /**
     * Рендерит React-компонент вместо установки HTML.
     */
    public function renderComponent(component:ReactComponent):Void {
        root.render(component);
    }
    
    // === Реализация IElement (для совместимости) ===
    
    public function setInnerHtml(html:String):Void {
        element.innerHTML = html;
    }
    
    public function appendChild(child:IElement):Void {
        var childHtml:ReactElement = cast child;
        element.appendChild(childHtml.element);
    }
    
    public function addEventListener(event:String, handler:Dynamic->Void):Void {
        element.addEventListener(event, handler);
    }
    
    public function getParent():Null<IElement> {
        if (element.parentElement == null) return null;
        return new ReactElement(element.parentElement);
    }
    
    public function getElement():Element return element;
    
    public function unmount():Void {
        root.unmount();
    }
}