package hide.engine.domain.entities;

class Rigidbody implements SceneComponent {
    public var id:String;
    public var name = "Rigidbody";
    public var mass:Float;
    public var useGravity:Bool;
    
    public function new(mass:Float = 1, useGravity:Bool = true) {
        this.id = Std.string(Date.now().getTime());
        this.mass = mass;
        this.useGravity = useGravity;
    }
    
    public function clone():SceneComponent {
        return new Rigidbody(mass, useGravity);
    }
}