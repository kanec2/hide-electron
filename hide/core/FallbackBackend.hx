package hide.core;

/**
 * Заглушка для сборок без бэкенда (веб, тесты).
 * Реализует IIdeBackend с минимальной функциональностью.
 */
class FallbackBackend implements IIdeBackend {
    public function new() {}
    public function init():Void {}
    public function isReady():Bool return true;
    
    public function openWindow(url:String, options:Dynamic, ?id:String):Void {
        js.Browser.window.open(url, id);
    }
    public function closeWindow(?id:String):Void {}
    public function focusWindow(?id:String):Void {}
    public function getCurrentWindowId():String return "main";
    
    public function createMenu(menuData:Array<Dynamic>):Void {}
    public function onMenuClick(handler:String->Void):Void {}
    public function updateMenuLabel(itemId:String, newLabel:String):Void {}
    public function setMenuItemEnabled(itemId:String, enabled:Bool):Void {}
    
    public function readFile(path:String, ?onComplete:String->Void, ?onError:String->Void):Void {
        if (onError != null) onError("Not implemented in fallback");
    }
    public function writeFile(path:String, content:String, ?onComplete:Bool->Void, ?onError:String->Void):Void {}
    public function watchPath(path:String, onChange:String->Void):Void {}
    public function unwatchPath(path:String):Void {}
    
    public function clearCache():Void { js.Browser.window.location.reload(); }
    public function reload():Void { js.Browser.window.location.reload(); }
    public function quit():Void {}
    public function getArgv():Array<String> return [];
    public function getAppPath():String return "./";
    public function showDevTools():Void {}
    
    public function sendToMain(channel:String, ?data:Dynamic):Void {}
    public function onFromMain(channel:String, handler:Dynamic->Void):Void {}
    
    // Диалоги
    public function chooseDirectory(callback:String->Void, ?createNew:Bool):Void { callback(null); }
    public function chooseFile(extensions:Array<String>, callback:String->Void):Void { callback(null); }
    public function chooseFileSave(defaultName:String, callback:String->Void):Void { callback(null); }
    public function getPath(relativePath:String):String return relativePath;
}