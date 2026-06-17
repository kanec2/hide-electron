package hide.engine.domain.entities;

/**
Сущность объекта сцены
*/
class SceneObject {
    public final id:String;
    public var name:String;
    public var transform:Transform;
    public var components:Array<SceneComponent>;
    public var parent:Null<SceneObject>;
    public var children:Array<SceneObject>;
    public var isActive:Bool;

    public function new(id:String, name:String) {
        this.id = id;
        this.name = name;
        this.transform = new Transform();
        this.components = [];
        this.children = [];
        this.isActive = true;
    }

    public function addChild(child:SceneObject):Void {
        child.parent = this;
        children.push(child);
    }

    public function removeChild(child:SceneObject):Void {
        child.parent = null;
        children.remove(child);
    }

    public function getComponent<T:SceneComponent>(type:Class<T>):Null<T> {
        for (c in components) {
            if (Std.isOfType(c, type)) return cast c;
        }
        return null;
    }

    public function addComponent(component:SceneComponent):Void {
        components.push(component);
    }

    public function removeComponent(componentId:String):Void {
        components = [for (c in components) if (c.id != componentId) c];
    }
}