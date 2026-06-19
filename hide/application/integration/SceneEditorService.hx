// application/integration/SceneEditorService.hx
package hide.application.integration;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineEventBus;
import hide.shared.types.IEventBus;
import hide.shared.events.ObjectSelected;
import hide.shared.events.ObjectChanged;
import hide.shared.events.SceneChanged;
import hx.injection.Service;
/**
 * Транслирует события между движком и IDE.
 * Это единственный класс, который знает ОБА EventBus.
 */
class SceneEditorService implements Service {
    private var sceneService:ISceneService;
    private var engineBus:IEngineEventBus;
    private var ideBus:IEventBus;
    
    public function new(
        sceneService:ISceneService,
        engineBus:IEngineEventBus,
        ideBus:IEventBus
    ) {
        trace('🌉 [Bridge] SceneEditorService initialized');
        this.sceneService = sceneService;
        this.engineBus = engineBus;
        this.ideBus = ideBus;
        
        // Движок → IDE
        engineBus.onObjectSelected(function(id) {
            trace('🌉 [Bridge] Engine → IDE: ObjectSelected($id)');
            ideBus.publish(ObjectSelected, new ObjectSelected(id));
        });
        
        engineBus.onObjectChanged(function(id) {
            trace('🌉 [Bridge] Engine → IDE: ObjectChanged($id)');
            ideBus.publish(ObjectChanged, new ObjectChanged(id));
        });

        engineBus.onSceneChanged(function() {
            ideBus.publish(SceneChanged, new SceneChanged());
        });
        // IDE → Движок
        /*
        ideBus.subscribe(ObjectSelected, function(e:ObjectSelected) {
            trace('🌉 [Bridge] IDE → Engine: ${e.objectId}');
            if (e.objectId != null) sceneService.select(e.objectId);
            else sceneService.deselect();
        });*/
    }
}