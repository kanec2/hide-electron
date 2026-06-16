package hide.infrastructure.ui;

import react.ReactDOM;
import react.ReactComponent;
import js.html.Element;

/**
 * Обёртка над React Root.
 * Управляет жизненным циклом React-компонента внутри DOM-узла.
 */
class ReactRoot {
    private var domNode:Element;
    private var root:Dynamic; // react-dom/client.Root
    private var isMounted:Bool = false;
    
    public function new(domNode:Element) {
        this.domNode = domNode;
    }
    
    /**
     * Рендерит React-компонент в DOM-узел.
     */
    public function render(component:ReactComponent):Void {
        if (root == null) {
            // React 18+ API: createRoot
            var ReactDOMClient = untyped require('react-dom/client');
            root = ReactDOMClient.createRoot(domNode);
        }
        
        root.render(component);
        isMounted = true;
    }
    
    /**
     * Размонтирует компонент и освобождает ресурсы.
     */
    public function unmount():Void {
        if (root != null && isMounted) {
            root.unmount();
            isMounted = false;
        }
    }
    
    public function get_isMounted():Bool return isMounted;
}