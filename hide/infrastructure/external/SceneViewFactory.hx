// hide/infrastructure/external/SceneViewFactory.hx
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hide.infrastructure.external.HtmlElement;
import hide.engine.domain.services.IRenderer;
import hide.engine.domain.services.ISceneService;
import hide.shared.types.IEventBus;
import hide.shared.events.SceneChanged;
import hx.injection.Service;

/**
 * Фабрика для Scene View.
 * Создаёт canvas, инициализирует рендерер, подписывается на изменения сцены.
 */
class SceneViewFactory implements IViewFactory implements Service {
    private var renderer:IRenderer;
    private var sceneService:ISceneService;
    private var eventBus:IEventBus;
    
    public function new(
        renderer:IRenderer,
        sceneService:ISceneService,
        eventBus:IEventBus
    ) {
        this.renderer = renderer;
        this.sceneService = sceneService;
        this.eventBus = eventBus;
    }
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        var htmlEl:HtmlElement = cast container;
        var domNode = htmlEl.getElement();
        
        // 1. Инициализируем рендерер
        renderer.init(domNode);
        
        // 2. Подписываемся на изменения сцены
        eventBus.subscribe(SceneChanged, function(_) {
            renderer.renderScene(sceneService.getRoot());
        });
        
        // 3. Первичный рендер
        renderer.renderScene(sceneService.getRoot());
        
        trace("🎬 [SceneViewFactory] Scene view created");
        
        return renderer;
    }
}