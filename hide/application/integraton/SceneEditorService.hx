// application/integration/SceneEditorService.hx
package hide.application.integration;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineEventBus;
import hide.shared.types.IEventBus;
import hide.shared.events.ObjectSelected;
import hide.shared.events.ObjectChanged;

/**
 * Транслирует события между движком и IDE.
 * Это единственный класс, который знает ОБА EventBus.
 */
class SceneEditorService {
    private var sceneService:ISceneService;
    private var engineBus:IEngineEventBus;
    private var ideBus:IEventBus;
    
    public function new(
        sceneService:ISceneService,
        engineBus:IEngineEventBus,
        ideBus:IEventBus
    ) {
        this.sceneService = sceneService;
        this.engineBus = engineBus;
        this.ideBus = ideBus;
        
        // Движок → IDE
        engineBus.onObjectSelected(function(id) {
            ideBus.publish(ObjectSelected, new ObjectSelected(id));
        });
        
        engineBus.onObjectChanged(function(id) {
            ideBus.publish(ObjectChanged, new ObjectChanged(id));
        });
        
        // IDE → Движок
        ideBus.subscribe(ObjectSelected, function(e:ObjectSelected) {
            if (e.objectId != null) sceneService.select(e.objectId);
            else sceneService.deselect();
        });
    }
}