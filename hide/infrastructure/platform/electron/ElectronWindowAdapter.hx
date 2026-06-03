package hide.infrastructure.platform.electron;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;
import hide.ElectronBackend; // Ваш существующий бэкенд

/**
 * Адаптер для Electron. Преобразует доменные вызовы в IPC.
 */
class ElectronWindowAdapter implements IWindowManager {
    private var backend:ElectronBackend;
    
    public function new(backend:ElectronBackend) {
        this.backend = backend;
    }
    
    public function getBounds():WindowBounds {
        return {
            x: backend.getWindowX(), y: backend.getWindowY(),
            width: backend.getOuterWidth(), height: backend.getOuterHeight()
        };
    }
    
    public function resizeBy(dw:Int, dh:Int):Void { backend.resizeBy(dw, dh); }
    public function resizeTo(w:Int, h:Int):Void { backend.resizeTo(w, h); }
    public function moveTo(x:Int, y:Int):Void { backend.moveTo(x, y); }
    public function setFullscreen(value:Bool):Void { backend.setFullscreen(value); }
    public function maximize():Void { backend.maximize(); }
    public function unmaximize():Void { backend.unmaximize(); }
    public function minimize():Void { backend.minimize(); }
    public function restore():Void { backend.restore(); }
    public function focus():Void { backend.focus(); }
    public function blur():Void { backend.blur(); }
    public function setTitle(title:String):Void { backend.setTitle(title); }
    
    public function on(event:WindowEvent, callback:Dynamic->Void):Void {
        // Преобразуем enum в строку, ожидаемую backend.onWindowEvent
        var eventName = switch event {
            case Focus: "focus"; case Blur: "blur";
            case Resize: "resize"; case Move: "move";
            case Maximize: "maximize"; case Unmaximize: "unmaximize";
            case Minimize: "minimize"; case Restore: "restore";
            case Close: "close";
        };
        backend.onWindowEvent(eventName, callback);
    }
    
    public function off(event:WindowEvent, callback:Dynamic->Void):Void {
        var eventName = switch event {
            case Focus: "focus"; case Blur: "blur";
            case Resize: "resize"; case Move: "move";
            case Maximize: "maximize"; case Unmaximize: "unmaximize";
            case Minimize: "minimize"; case Restore: "restore";
            case Close: "close";
        };
        backend.removeWindowEventListener(eventName, callback);
    }
}