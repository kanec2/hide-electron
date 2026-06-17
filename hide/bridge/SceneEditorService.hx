package hide.bridge;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.SceneComponent;
import hide.shared.types.IEventBus;
import hide.shared.events.ObjectSelected;
import hide.shared.events.ObjectChanged;
import hx.injection.Service;

/**
Мост между IDE и Engine.
Синхронизирует состояние между UI и движком.
*/
class SceneEditorService implements Service {
    private var sceneService:ISceneService;
    private var eventBus:IEventBus;

    public function new(sceneService:ISceneService, eventBus:IEventBus) {
        this.sceneService = sceneService;
        this.eventBus = eventBus;
        
        // Синхронизация: клик в Hierarchy → выделение в Engine
        eventBus.subscribe(ObjectSelected, function(e:ObjectSelected) {
            if (e.objectId != null) {
                sceneService.select(e.objectId);
            } else {
                sceneService.deselect();
            }
        });
    }

    public function getSceneService():ISceneService {
        return sceneService;
    }

    public function getRoot():SceneObject {
        return sceneService.getRoot();
    }

    public function getSelected():Null<SceneObject> {
        return sceneService.getSelected();
    }

    public function selectObject(id:String):Void {
        eventBus.publish(ObjectSelected, new ObjectSelected(id));
    }

    public function updateTransform(id:String, transform:Transform):Void {
        sceneService.setTransform(id, transform);
        eventBus.publish(ObjectChanged, new ObjectChanged(id));
    }
}