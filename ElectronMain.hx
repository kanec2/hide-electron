import haxe.io.Path;
// 👇 Ваши импорты (electron.main.*)
import electron.main.App;
import electron.main.BrowserWindow;
import electron.main.IpcMain;
import electron.main.Menu; // 👈 Добавим для будущего меню

import sys.io.File;
import haxe.Json;

// Electron предоставляет __dirname в main процессе
@:native("__dirname") extern var __dirname:String;

@:keep
class ElectronMain {
    
    // 👇 УДАЛЯЕМ static var mainWindow:BrowserWindow; 
    // AutoWindow уже хранит окно в AutoWindow.window
    
    static var isQuitting:Bool = false;

    static function main():Void {
        new ElectronMain();
    }

    public function new() {
        // Запускаем AutoWindow с колбэком
        AutoWindow.start({
            onReady: startup
        });
    }

    public function startup():Void {
        trace("🚀 Startup...");
        setupIpcHandlers();
        
        // 👇 Здесь позже добавим: setupMenu();
    }

    // 👇 createMainWindow() удаляем полностью - AutoWindow делает это сам

    static function setupIpcHandlers():Void {
        // 1. Выход из приложения
        IpcMain.on("app:quit", function(_) {
            isQuitting = true;
            // Используем окно из AutoWindow
            if (AutoWindow.window != null && !AutoWindow.window.isDestroyed()) {
                AutoWindow.window.close();
            }
            App.quit();
        });

        // 2. Перезагрузка
        IpcMain.on("app:reload", function(_) {
            if (AutoWindow.window != null && !AutoWindow.window.isDestroyed()) {
                AutoWindow.window.reload();
            }
        });

        // 3. Очистка кэша
        IpcMain.on("app:clearCache", function(event:Dynamic) {
            if (AutoWindow.window != null) {
                AutoWindow.window.webContents.session.clearCache().then(_ -> {
                    event.reply("app:clearCache:done");
                }).catchError(err -> {
                    trace("Cache clear error: " + err);
                    event.reply("app:clearCache:error");
                });
            }
        });

        // 👇 4. НОВОЕ: Открытие дочерних окон (для openSubView из Ide.hx)
        IpcMain.on("window:open", function(event:Dynamic, data:Dynamic) {
            var opts:Dynamic = {
                width: data.options.width != null ? data.options.width : 800,
                height: data.options.height != null ? data.options.height : 600,
                title: data.options.title != null ? data.options.title : "Hide",
                // Важно: те же настройки безопасности, что и у главного окна
                webPreferences: {
                    nodeIntegration: true,
                    contextIsolation: false,
                    enableRemoteModule: true
                }
            };
            
            var child = new BrowserWindow(opts);
            child.loadFile(data.url);
            
            #if debug
            child.webContents.openDevTools({ mode: "detach" });
            #end
            
            // Опционально: сообщаем обратно, что окно создано
            // event.reply("window:opened", { id: child.id });
        });
    }
}