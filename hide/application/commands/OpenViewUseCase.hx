// hide/application/commands/OpenViewUseCase.hx

package hide.application.commands;

import hide.infrastructure.external.HtmlElement;
import hide.domain.services.ILayoutEngine;
import hide.domain.valueobjects.DisplayPosition;
import hide.application.services.ViewRegistry;
import js.html.Element;

class OpenViewUseCase {
    private var layoutEngine:ILayoutEngine;
    private var viewRegistry:ViewRegistry;

    public function new(layoutEngine:ILayoutEngine, viewRegistry:ViewRegistry) {
        this.layoutEngine = layoutEngine;
        this.viewRegistry = viewRegistry;
    }

    public function execute(viewName:String, state:Dynamic, ?position:DisplayPosition):Void {
        var view = viewRegistry.find(viewName);
        if (view == null) {
            throw "View not found: $viewName";
        }

        var factory = viewRegistry.getFactory(viewName);
        if (factory == null) {
            throw "View factory not found: $viewName";
        }

        layoutEngine.open(viewName, state, position != null ? position : DisplayPosition.Center);
    }
}