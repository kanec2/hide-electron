// hide/engine/infrastructure/SceneServiceImpl.hx
package hide.engine.infrastructure;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineEventBus;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.SceneComponent;
import hide.engine.domain.entities.MeshRenderer;
import hide.engine.domain.entities.Rigidbody;
import hx.injection.Service;

/**
 * Реализация ISceneService.
 * ❌ УБРАНО: import hide.shared.types.IEventBus;
 * ❌ УБРАНО: import hide.shared.events.*;
 * ✅ Использует только IEngineEventBus (изолированный от IDE)
 */
class SceneServiceImpl implements ISceneService implements Service {
    private var root:SceneObject;
    private var selectedId:Null<String>;
    private var eventBus:IEngineEventBus;  // ← Свой EventBus движка!
    private var objectIndex:Map<String, SceneObject>;
    
    public function new(eventBus:IEngineEventBus) {
        this.eventBus = eventBus;
        this.objectIndex = new Map();
        root = createSampleScene();
    }
    
    private function createSampleScene():SceneObject {
        var scene = new SceneObject("scene", "SampleScene");
        
        var camera = new SceneObject("camera", "Main Camera");
        var light = new SceneObject("light", "Directional Light");
        
        var player = new SceneObject("player", "Player");
        player.transform = new Transform(0, 1.5, 0);
        player.addComponent(new MeshRenderer("Player.mesh", "Default-Diffuse"));
        player.addComponent(new Rigidbody(1, true));
        
        var ground = new SceneObject("ground", "Ground");
        ground.transform = new Transform(0, 0, 0);
        ground.addComponent(new MeshRenderer("Ground.mesh", "Ground-Material"));
        
        scene.addChild(camera);
        scene.addChild(light);
        scene.addChild(player);
        scene.addChild(ground);
        
        indexObject(scene);
        return scene;
    }
    
    private function indexObject(obj:SceneObject):Void {
        objectIndex.set(obj.id, obj);
        for (child in obj.children) indexObject(child);
    }
    
    public function getRoot():SceneObject return root;
    
    public function getObject(id:String):Null<SceneObject> {
        return objectIndex.get(id);
    }
    
    public function getSelected():Null<SceneObject> {
        return selectedId != null ? objectIndex.get(selectedId) : null;
    }
    
    public function getAll():Array<SceneObject> {
        return [for (obj in objectIndex) obj];
    }
    
    public function select(id:String):Void {
        if (!objectIndex.exists(id)) return;
        selectedId = id;
        // ✅ ИСПРАВЛЕНО: используем emitObjectSelected вместо publish
        eventBus.emitObjectSelected(id);
    }
    
    public function deselect():Void {
        selectedId = null;
        // ✅ ИСПРАВЛЕНО: используем emitObjectSelected вместо publish
        eventBus.emitObjectSelected(null);
    }
    
    public function rename(id:String, newName:String):Void {
        var obj = getObject(id);
        if (obj == null) return;
        obj.name = newName;
        notifyChanged(id);
    }
    
    public function setTransform(id:String, transform:Transform):Void {
        var obj = getObject(id);
        if (obj == null) return;
        obj.transform = transform;
        notifyChanged(id);
    }
    
    public function addComponent(id:String, component:SceneComponent):Void {
        var obj = getObject(id);
        if (obj == null) return;
        obj.addComponent(component);
        notifyChanged(id);
    }
    
    public function removeComponent(id:String, componentId:String):Void {
        var obj = getObject(id);
        if (obj == null) return;
        obj.removeComponent(componentId);
        notifyChanged(id);
    }
    
    public function onObjectSelected(callback:String->Void):Void {
        eventBus.onObjectSelected(callback);
    }
    
    public function onObjectChanged(callback:String->Void):Void {
        eventBus.onObjectChanged(callback);
    }
    
    public function onSceneChanged(callback:Void->Void):Void {
        eventBus.onSceneChanged(callback);
    }
    
    private function notifyChanged(id:String):Void {
        // ✅ ИСПРАВЛЕНО: используем emitObjectChanged вместо publish
        eventBus.emitObjectChanged(id);
        eventBus.emitSceneChanged();
    }
}