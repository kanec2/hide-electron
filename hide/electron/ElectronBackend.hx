package hide.electron;

import hide.core.IIdeBackend;
import electron.renderer.IpcRenderer; // 👇 Ваш импорт из electron.main.*


class ElectronBackend implements IIdeBackend {
    
    var menuClickHandler:Null<String->Void> = null;

    public function new() {}
    
    public function init():Void {
        trace("[ElectronBackend] init()");
        
        // Слушаем клики из Main Process
        IpcRenderer.on("menu:click", function(event, data) {
            trace("[ElectronBackend] 📥 menu:click received");
            if (menuClickHandler != null && data != null && data.id != null) {
                menuClickHandler(data.id);
            }
        });
    }
    
    public function isReady():Bool return true;
    
    // === Окна ===
    public function openWindow(url:String, options:Dynamic, ?id:String):Void {
        // Если это суб-вью — отправляем событие внутри renderer, а не в Main
        if (url.indexOf("?subView=") != -1) {
            trace("[ElectronBackend] 🪟 Sub-view request, dispatching locally");
            
            // Парсим параметры
            var params = new haxe.ds.StringMap<String>();
            var query = url.split("?")[1];
            if (query != null) {
                for (pair in query.split("&")) {
                    var parts = pair.split("=");
                    if (parts.length == 2) {
                        params.set(parts[0], haxe.Uri.decode(parts[1]));
                    }
                }
            }
            
            // Если есть subView — вызываем WindowManager.openSubView напрямую
            if (params.exists("subView") && window.hide != null && window.hide.Ide != null) {
                var componentName = params.get("subView");
                var state = null;
                if (params.exists("state")) {
                    try {
                        state = haxe.Json.parse(haxe.Uri.decode(params.get("state")));
                    } catch(_) {}
                }
                var position = params.get("pos");
                
                window.hide.Ide.inst.open(componentName, state, position);
            }
            return;
        }
        
        // Для настоящих окон — отправляем в Main Process
        IpcRenderer.send("window:open", { url: url, options: options, id: id });
    }
    public function closeWindow(?id:String):Void { trace("[ElectronBackend] closeWindow"); }
    public function focusWindow(?id:String):Void { trace("[ElectronBackend] focusWindow"); }
    public function getCurrentWindowId():String return "main";
    
    // === Меню ===
    public function createMenu(menuData:Array<Dynamic>):Void {
        // Явная сериализация для надёжности IPC
        var serialized = haxe.Json.stringify(menuData);
        trace("[ElectronBackend] 📤 Sending menu JSON: " + serialized);
        IpcRenderer.send("menu:build", menuData);
    }

    public function onMenuClick(handler:String->Void):Void {
        trace("[ElectronBackend] 📡 onMenuClick registered");
        menuClickHandler = handler;
    }

    public function updateMenuLabel(itemId:String, newLabel:String):Void {}
    public function setMenuItemEnabled(itemId:String, enabled:Bool):Void {}
    
    // === Файлы ===
    public function readFile(path:String, ?onComplete:String->Void, ?onError:String->Void):Void {
        if (onError != null) onError("Not implemented yet");
    }
    public function writeFile(path:String, content:String, ?onComplete:Bool->Void, ?onError:String->Void):Void {}
    public function watchPath(path:String, onChange:String->Void):Void {}
    public function unwatchPath(path:String):Void {}
    
    // === Приложение ===
    public function clearCache():Void { IpcRenderer.send("app:clearCache"); }
    public function reload():Void { IpcRenderer.send("app:reload"); }
    public function quit():Void { IpcRenderer.send("app:quit"); }
    public function getArgv():Array<String> return [];
    public function getAppPath():String return "./";

    // === Заглушки для диалогов (реализуем позже) ===
    public function chooseDirectory(callback:String->Void, ?createNew:Bool):Void { callback(null); }
    public function chooseFile(extensions:Array<String>, callback:String->Void):Void { callback(null); }
    public function chooseFileSave(defaultName:String, callback:String->Void):Void { callback(null); }
    public function getPath(relativePath:String):String return relativePath;
    public function showDevTools():Void {
        #if electron
        untyped __js__("require('electron').remote.getCurrentWindow().webContents.openDevTools()");
        #end
    }
    
    // === IPC ===
    public function sendToMain(channel:String, ?data:Dynamic):Void {
        IpcRenderer.send(channel, data);
    }
    
    public function onFromMain(channel:String, handler:Dynamic->Void):Void {
        IpcRenderer.on(channel, function(event, args) handler(args));
    }
}