package hide.infrastructure.ui;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hide.infrastructure.external.HtmlElement;
import react.React;
import react.ReactComponent;
import hx.injection.Service;
import react.ReactDOM;
/**
 * Фабрика, которая рендерит React-компонент в контейнер.
 * Используется для интеграции React-UI с GoldenLayout.
 */
class ReactViewFactory implements IViewFactory implements Service {
    private var componentClass:Class<ReactComponent>;
    private var defaultProps:Dynamic;
    
    // ✅ Конструктор без параметров для DI
    public function new() {
        this.defaultProps = {};
    }
    
    // ✅ Метод для настройки фабрики (Fluent API)
    public function withComponent(componentClass:Class<ReactComponent>, ?defaultProps:Dynamic):ReactViewFactory {
        this.componentClass = componentClass;
        this.defaultProps = defaultProps != null ? defaultProps : {};
        return this;
    }
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        if (componentClass == null) {
            throw "ReactViewFactory: componentClass not set. Call withComponent() first.";
        }
        // 1. Получаем реальный DOM-элемент
        var htmlElement:HtmlElement = cast container;
        var domNode = htmlElement.getElement();
        // ✅ ЗАЩИТА: Проверяем, что domNode действительно является DOM-элементом
        if (domNode == null || domNode.nodeType == null) {
            trace("⚠️ CRITICAL: domNode is invalid! Type: ", js.Lib.typeof(domNode), " Value: ", domNode);
            // Создаём запасной div, чтобы приложение не упало, и мы могли увидеть ошибку в UI
            domNode = js.Browser.document.createElement("div");
            domNode.innerHTML = "<div style='color:red; padding:10px;'>Error: Invalid DOM container for React</div>";
        }
        // 2. Создаём React Root
        var reactRoot = new ReactRoot(domNode);
        
        // 3. Формируем пропсы: состояние + коллбэки
        // ✅ ИСПРАВЛЕНО: пропсы — это просто анонимный объект Haxe
        var props = {
            initialState: state,
            defaultProps: defaultProps,
            onUnmount: function() {}
        };
        
        // 4. Рендерим компонент
        // ✅ ИСПРАВЛЕНО: правильный порядок аргументов для haxe-react
        var reactElement:Dynamic = React.createElement(componentClass, props);
        // Монтирование через react-dom
        //var ReactDOM = untyped require("react-dom");
        ReactDOM.render(reactElement, domNode);
        
        // 5. Возвращаем root для возможности размонтирования
        return reactRoot;
    }
}