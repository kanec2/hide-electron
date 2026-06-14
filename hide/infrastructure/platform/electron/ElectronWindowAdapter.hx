package hide.infrastructure.platform.electron;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;
import hx.injection.Service;

using tink.CoreApi;
/**
 * Адаптер для Electron. Преобразует доменные вызовы в IPC через ElectronIpcBridge.
 */
class ElectronWindowAdapter implements IWindowManager {
    private var ipcBridge:ElectronIpcBridge;

    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }

    public function getBounds():WindowBounds {
        // Заглушка: в реальном приложении это должен быть IPC вызов:
        // return ipcBridge.invokeSync("window:getBounds");
        return { x: 0, y: 0, width: 800, height: 600 };
    }

    public function resizeBy(dw:Int, dh:Int):Void { 
        ipcBridge.invokeSync("window:resizeBy", { dw: dw, dh: dh }); 
    }

    public function moveTo(x:Int, y:Int):Void { 
        ipcBridge.invokeSync("window:moveTo", { x: x, y: y }); 
    }

    public function maximize():Void { 
        ipcBridge.invokeSync("window:maximize"); 
    }

    public function unmaximize():Void { 
        ipcBridge.invokeSync("window:unmaximize"); 
    }

    public function focus():Void { 
        ipcBridge.invokeSync("window:focus"); 
    }

    public function blur():Void { 
        ipcBridge.invokeSync("window:blur"); 
    }

    public function setTitle(title:String):Void { 
        ipcBridge.invokeSync("window:setTitle", title); 
    }

    public function getTitle():String { 
        return ipcBridge.invokeSync("window:getTitle"); 
    }

    public function enterFullscreen():Void { 
        ipcBridge.invokeSync("window:enterFullscreen"); 
    }

    public function leaveFullscreen():Void { 
        ipcBridge.invokeSync("window:leaveFullscreen"); 
    }

    public function showDevTools():Void { 
        ipcBridge.invokeSync("window:showDevTools"); 
    }

    public function on(event:WindowEvent, callback:Dynamic->Void):Void {
        var eventName = switch event {
            case Focus: "window:focus";
            case Blur: "window:blur";
            case Resize: "window:resize";
            case Move: "window:move";
            case Maximize: "window:maximize";
            case Unmaximize: "window:unmaximize";
            case Minimize: "window:minimize";
            case Restore: "window:restore";
            case Close: "window:close";
            case FullscreenEnter: "window:fullscreen-enter";
            case FullscreenLeave: "window:fullscreen-leave";
        }
        ipcBridge.on(eventName, callback);
    }

    public function off(event:WindowEvent, callback:Dynamic->Void):Void {
        var eventName = switch event {
            case Focus: "window:focus";
            case Blur: "window:blur";
            case Resize: "window:resize";
            case Move: "window:move";
            case Maximize: "window:maximize";
            case Unmaximize: "window:unmaximize";
            case Minimize: "window:minimize";
            case Restore: "window:restore";
            case Close: "window:close";
            case FullscreenEnter: "window:fullscreen-enter";
            case FullscreenLeave: "window:fullscreen-leave";
        }
        ipcBridge.off(eventName, callback);
    }

    public function dispose():Void {
        // Очистка подписок, если необходимо
    }
}