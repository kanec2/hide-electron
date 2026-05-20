package hide.modules;
import hide.core.Ide;

class FileSystem {
    var ide:Ide;
    public function new(ide:Ide) { this.ide = ide; }
    public function read(path:String, onComplete:String->Void, ?onError:String->Void):Void {}
    public function watch(path:String, onChange:String->Void):Void {}
}