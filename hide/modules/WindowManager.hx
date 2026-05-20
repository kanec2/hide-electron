package hide.modules;
import hide.core.Ide;

class WindowManager {
    var ide:Ide;
    public function new(ide:Ide) { this.ide = ide; }
    public function openSubView(componentName:String, state:Dynamic, events:{}):Void {}
    public function closeAll():Void {}
}