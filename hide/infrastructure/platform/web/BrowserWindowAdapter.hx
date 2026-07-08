package hide.infrastructure.platform.web;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;
import hx.injection.Service;
class BrowserWindowAdapter implements IWindowManager implements Service {
    public function new() {}
    public function resizeBy(dw:Int, dh:Int):Void {}
    public function moveTo(x:Int, y:Int):Void {}
    public function maximize():Void {}
    public function unmaximize():Void {}
    public function minimize():Void {}
    public function focus():Void {}
    public function blur():Void {}
    public function setTitle(title:String):Void {
        js.Browser.document.title = title;
    }
    public function getTitle():String {
        return js.Browser.document.title;
    }
    public function enterFullscreen():Void {
        js.Browser.document.documentElement.requestFullscreen();
    }
    public function leaveFullscreen():Void {
        js.Browser.document.exitFullscreen();
    }
    public function showDevTools():Void {}

    public function on(event:WindowEvent, cb:Dynamic->Void):Void {}
    public function off(event:WindowEvent, cb:Dynamic->Void):Void {}

    public function getBounds():WindowBounds {
        return {
            x: 0,
            y: 0,
            width: js.Browser.window.innerWidth,
            height: js.Browser.window.innerHeight
        };
    }

    public function dispose():Void {}
}