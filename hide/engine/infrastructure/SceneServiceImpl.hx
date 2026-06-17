package hide.engine.infrastructure;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.SceneComponent;
import hide.engine.domain.entities.MeshRenderer;
import hide.engine.domain.entities.Rigidbody;
import hide.shared.types.IEventBus;
import hide.shared.events.ObjectSelected;
import hide.shared.events.ObjectChanged;
import hx.injection.Service;

class SceneServiceImpl implements ISceneService implements Service {
    private var root:SceneObject;
    private var selectedId:Null<String>;
    private var eventBus:IEventBus;
    private var objectIndex:Map<String, SceneObject>;

    private var onObjectSelectedCallbacks:Array<String->Void>;
    private var onObjectChangedCallbacks:Array<String->Void>;
    private var onSceneChangedCallbacks:Array<Void->Void>;

    public function new(eventBus:IEventBus) {
        this.eventBus = eventBus;
        this.objectIndex = new Map();
        this.onObjectSelectedCallbacks = [];
        this.onObjectChangedCallbacks = [];
        this.onSceneChangedCallbacks = [];
        
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
        eventBus.publish(ObjectSelected, new ObjectSelected(id));
        for (cb in onObjectSelectedCallbacks) cb(id);
    }

    public function deselect():Void {
        selectedId = null;
        eventBus.publish(ObjectSelected, new ObjectSelected(null));
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
        onObjectSelectedCallbacks.push(callback);
    }

    public function onObjectChanged(callback:String->Void):Void {
        onObjectChangedCallbacks.push(callback);
    }

    public function onSceneChanged(callback:Void->Void):Void {
        onSceneChangedCallbacks.push(callback);
    }

    private function notifyChanged(id:String):Void {
        eventBus.publish(ObjectChanged, new ObjectChanged(id));
        for (cb in onObjectChangedCallbacks) cb(id);
        for (cb in onSceneChangedCallbacks) cb();
    }
}