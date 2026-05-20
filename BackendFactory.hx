package ;


class BackendFactory {
    
    public static function create():IWindowBackend {
        #if electron
        return new WindowManager();

        #else
        // Fallback для веб-сборки или тестов
        return new FallbackBackend();
        #end
    }
}

// Простая заглушка для non-desktop сборок
class FallbackBackend implements IWindowBackend {
    public function new() {}
    public function init():Void {}
    public function openWindow(url:String, options:Dynamic, ?id:String):Dynamic {
        js.Browser.window.open(url, id);
        return null;
    }
    public function on(channel:String, handler:Dynamic->Void):Void {}
    public function send(channel:String, ?data:Dynamic):Void {}
    public function clearCache():Void {}
    public function reload():Void { js.Browser.window.location.reload(); }
    public function getCurrentWindow():Dynamic { return js.Browser.window; }
}