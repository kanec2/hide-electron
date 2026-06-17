package hide.engine.domain.entities;

class MeshRenderer implements SceneComponent {
    public var id:String;
    public var name = "MeshRenderer";
    public var meshPath:String;
    public var materialPath:String;
    
    public function new(meshPath:String, materialPath:String) {
        this.id = Std.string(Date.now().getTime());
        this.meshPath = meshPath;
        this.materialPath = materialPath;
    }
    
    public function clone():SceneComponent {
        return new MeshRenderer(meshPath, materialPath);
    }
}
