package hide.infrastructure.platform.electron.nwjs;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;
import hx.injection.Service;
class NwWindowAdapter implements IWindowManager implements Service {

    public function new() {}
    
    public function resizeBy(dw:Int, dh:Int):Void {}
    public function moveTo(x:Int, y:Int):Void {}
    public function maximize():Void {}
    public function unmaximize():Void {}
    public function minimize():Void {}
    public function focus():Void {}
    public function blur():Void {}
    public function setTitle(title:String):Void {}
    public function getTitle():String { return ""; }
    public function enterFullscreen():Void {}
    public function leaveFullscreen():Void {}
    public function showDevTools():Void {}

    public function on(event:WindowEvent, cb:Dynamic->Void):Void {}
    public function off(event:WindowEvent, cb:Dynamic->Void):Void {}

    public function getBounds():WindowBounds {
        return { x: 0, y: 0, width: 800, height: 600 };
    }

    public function dispose():Void {}
    // и т.д.
}