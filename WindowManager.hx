package ;

import electron.main.BrowserWindow;
import electron.BrowserWindowConstructorOptions;
import electron.main.IpcMain;
import electron.renderer.IpcRenderer;
import IWindowBackend;

class WindowManager implements IWindowBackend {
    
    public static var mainWindow:BrowserWindow;
    static var listeners:Map<String, Array<Dynamic->Void>> = new Map();
    
    public function new() {}
    
    public function init():Void {
        // Инициализация обработчиков IPC в main process
        #if electron_main
        setupIpcHandlers();
        #end
    }
    
    /**
     * Настройка IPC-обработчиков (выполняется только в main process)
     */
    #if electron_main
    static function setupIpcHandlers():Void {
        IpcMain.on("app:reload", function(event, args) {
            for (win in BrowserWindow.getAllWindows()) {
                win.reload();
            }
        });
        
        IpcMain.on("app:clearCache", function(event, args) {
            electron.main.Session.defaultSession.clearCache().then(function(_) {
                event.reply("app:clearCache:done");
            });
        });
    }
    #end
    
    public function openWindow(url:String, options:Dynamic, ?id:String):Dynamic {
        #if electron
        var winOptions:BrowserWindowConstructorOptions = {
            width: options.width != null ? options.width : 1200,
            height: options.height != null ? options.height : 800,
            
            // 👇 КЛЮЧЕВОЕ: делаем окно дочерним главного
            parent: mainWindow,  // <-- Это группирует окна в доке/панели задач
            
            // 👇 Дополнительно: поведение как у панели/инспектора
            #if mac
            type: 'panel',  // На macOS: нет иконки в доке, окно "плавающее"
            #end
            
            // Всегда наверху (опционально, как в оригинальном Hide)
            // alwaysOnTop: options.alwaysOnTop == true,
            
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false,
                preload: null
            }
        };
        
        var win = new BrowserWindow(winOptions);
        
        if (options.id != null) {
            win.setTitle(options.id);
        }
        
        if (url.indexOf("://") == -1) {
            win.loadFile(url);
        } else {
            win.loadURL(url);
        }
        
        #if debug
        win.webContents.openDevTools({ mode: 'detach' });
        #end
        
        return win;
        #else
        return null;
        #end
    }
    /*
    public function openWindow(url:String, options:Dynamic, ?id:String):Dynamic {
        #if electron
        var winOptions:BrowserWindowConstructorOptions = {
            width: options.width != null ? options.width : 1200,
            height: options.height != null ? options.height : 800,
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false, // Для совместимости с текущим кодом
                preload: null // Можно добавить позже для безопасности
            }
        };
        
        var win = new BrowserWindow(winOptions);
        
        // Обработка параметров окна
        if (options.id != null) {
            win.setTitle(options.id);
        }
        
        // Загрузка URL
        if (url.indexOf("://") == -1) {
            // Относительный путь -> loadFile
            win.loadFile(url);
        } else {
            win.loadURL(url);
        }
        
        // Авто-показ DevTools в дев-режиме
        #if debug
        win.webContents.openDevTools({ mode: 'detach' });
        #end
        
        return win;
        #else
        return null;
        #end
    }*/
    
    public function on(channel:String, handler:Dynamic->Void):Void {
        #if electron
        #if electron_main
            IpcMain.on(channel, function(event, args) {
                handler(args);
            });
        #else
            IpcRenderer.on(channel, function(event, args) {
                handler(args);
            });
            // Сохраняем для возможного удаления
            if (!listeners.exists(channel)) {
                listeners.set(channel, []);
            }
            listeners.get(channel).push(handler);
        #end
        #end
    }
    
    public function send(channel:String, ?data:Dynamic):Void {
        #if electron
        #if electron_main
            // В main process отправляем в конкретное окно или все
            var wins = BrowserWindow.getAllWindows();
            for (win in wins) {
                win.webContents.send(channel, data);
            }
        #else
            IpcRenderer.send(channel, data);
        #end
        #end
    }
    
    public function clearCache():Void {
        #if electron
        #if !electron_main
            // Запрос к main process на очистку
            send("app:clearCache");
            on("app:clearCache:done", function(_) {
                // Callback можно передать через параметр, если нужно
                js.Browser.window.localStorage.clear();
            });
        #end
        #end
    }
    
    public function reload():Void {
        #if electron
        send("app:reload");
        #end
    }
    
    public function getCurrentWindow():Dynamic {
        #if electron
        #if electron_main
            return BrowserWindow.getFocusedWindow();
        #else
            return electron.remote.BrowserWindow.getFocusedWindow();
            // Примечание: @electron/remote может потребоваться для доступа из renderer
        #end
        #else
        return null;
        #end
    }
}