// plugins/console/ConsoleViewFactory.hx

package plugins.console;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;

/**
 * Реализация IViewFactory для ConsoleView.
 * Использует IElement вместо js.html.Element.
 */
class ConsoleViewFactory implements IViewFactory {
    public function create(container:IElement, state:Dynamic):Dynamic {
        return new ConsoleView(container, state);
    }
}