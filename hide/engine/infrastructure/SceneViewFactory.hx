// hide/infrastructure/external/SceneViewFactory.hx
package hide.infrastructure.external;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hide.infrastructure.external.HtmlElement;
import hide.engine.infrastructure.SceneViewportController;
import hx.injection.Service;

class SceneViewFactory implements IViewFactory implements Service {
    private var sceneViewportController:SceneViewportController;
    
    public function new(sceneViewportController:SceneViewportController) {
        this.sceneViewportController = sceneViewportController;
    }
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        var htmlEl:HtmlElement = cast container;
        var domNode = htmlEl.getElement();
        
        // Просто привязываем контроллер к DOM
        sceneViewportController.attachTo(domNode);
        
        trace("🎬 [SceneViewFactory] Scene viewport created");
        return sceneViewportController;
    }
}