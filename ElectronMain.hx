import electron.main.App;
import electron.main.BrowserWindow;

// Electron предоставляет __dirname в main процессе
@:native("__dirname") extern var __dirname:String;

/**
 * Точка входа Electron Main Process.
 * Запускает AutoWindow для создания окна и передачи управления.
 */
class ElectronMain {
    
    static function main():Void {
        // Запускаем AutoWindow с колбэком onReady
        AutoWindow.start({
            onReady: startup
        });
    }
    
    static function startup():Void {
        trace("🚀 ElectronMain: Startup complete");
        // Здесь можно добавить дополнительную настройку, если потребуется
    }
}