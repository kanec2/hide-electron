import electron.main.Menu;
import haxe.io.Path;
import electron.main.App;
import electron.main.BrowserWindow;
import electron.main.IpcMain;

import sys.io.File;
import haxe.Json;


// Electron предоставляет __dirname в main процессе
@:native("__dirname") extern var __dirname:String;


/**
 * Конфигурация окна (опциональная)
 */
typedef AutoWindowConfig = {
    ?width:Int, ?height:Int, ?minWidth:Int, ?minHeight:Int,
    ?title:String, ?icon:String, ?show:Bool, ?frame:Bool,
    ?x:Int, ?y:Int, ?url:String,
    ?onReady:Void->Void, ?onClose:Void->Void
}

/**
 * Автоматический менеджер главного окна.
 * Читает package.json, применяет дефолты, создаёт окно и настраивает базовые IPC.
 */
class AutoWindow {
    public static var window(default, null):BrowserWindow;
    static var cfg:AutoWindowConfig;

    /**
     * Запуск приложения с автоматическим созданием окна.
     * Вызывать в main().
     */
    public static function start(?overrides:AutoWindowConfig):Void {
        // 1. Загружаем базовую конфигурацию из package.json
        cfg = loadPackageConfig();
        trace(cfg);
        // 2. Применяем внутренние дефолты для отсутствующих полей
        applyDefaults();
        trace(cfg);
        // 3. Накладываем пользовательские переопределения (если переданы)
        if (overrides != null) {
            if (overrides.width != null) cfg.width = overrides.width;
            if (overrides.height != null) cfg.height = overrides.height;
            if (overrides.minWidth != null) cfg.minWidth = overrides.minWidth;
            if (overrides.minHeight != null) cfg.minHeight = overrides.minHeight;
            if (overrides.title != null) cfg.title = overrides.title;
            if (overrides.icon != null) cfg.icon = overrides.icon;
            if (overrides.show != null) cfg.show = overrides.show;
            if (overrides.frame != null) cfg.frame = overrides.frame;
            if (overrides.x != null) cfg.x = overrides.x;
            if (overrides.y != null) cfg.y = overrides.y;
            if (overrides.url != null) cfg.url = overrides.url;
            if (overrides.onReady != null) cfg.onReady = overrides.onReady;
            if (overrides.onClose != null) cfg.onClose = overrides.onClose;
        }
            trace(cfg);
        // 4. Запуск жизненного цикла
        App.whenReady().then(function(_) {
            createWindow();
            setupLifecycle();
            setupIpc();
            
            // Вызываем колбэк, если он задан
            if (cfg.onReady != null) cfg.onReady();
        });
    }

    /** Чтение секции "window" из package.json */
    static function loadPackageConfig():AutoWindowConfig {
        try {
            var pkgPath = Path.join([__dirname, "package.json"]);
            var pkg:Dynamic = Json.parse(File.getContent(pkgPath));
            var win:Dynamic = pkg.window != null ? pkg.window : {};
            
            return {
                width: win.width, 
                height: win.height,
                minWidth: win.min_width, 
                minHeight: win.min_height,
                title: win.title, 
                icon: win.icon,
                show: win.show, 
                frame: win.frame,
                x: win.x,
                y: win.y,
                url: win.url
            };
        } catch(_) return {};
    }

    /** Применение дефолтов для Hide IDE */
    static function applyDefaults():Void {
        if (cfg.width == null) cfg.width = 1200;
        if (cfg.height == null) cfg.height = 800;
        if (cfg.title == null) cfg.title = "HIDE IDE";
        if (cfg.url == null) cfg.url = "app-electron.html";
        if (cfg.show == null) cfg.show = true;
        if (cfg.frame == null) cfg.frame = false;
    }

    /** Создание окна */
    static function createWindow():Void {
        var opts:Dynamic = {
            width: cfg.width, height: cfg.height,
            minWidth: cfg.minWidth, minHeight: cfg.minHeight,
            title: cfg.title, show: false, // Показываем после ready-to-show
            frame: cfg.frame,
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false,
                enableRemoteModule: true
            }
        };

        if (cfg.icon != null) opts.icon = Path.join([__dirname, cfg.icon]);
        if (cfg.x != null && cfg.y != null) { opts.x = cfg.x; opts.y = cfg.y; }

        window = new BrowserWindow(opts);
        window.loadFile(cfg.url);

        // Показ после загрузки контента (убирает мигание)
        window.on("ready-to-show", function() {
            if (cfg.show) window.show();
            window.focus();
        });

        // Кастомная логика при закрытии
        window.on("close", function(_) {
            if (cfg.onClose != null) cfg.onClose();
        });

        #if debug
        //window.webContents.openDevTools({ mode: "detach" });
        #end
    }

    /** Жизненный цикл приложения */
    static function setupLifecycle():Void {
        // Закрытие всех окон → выход из приложения (кроме macOS)
        App.on("window-all-closed", function() {
            if (Sys.systemName() != "Mac") {
                App.quit();
            }
        });
        App.on("activate", function() {
            if (BrowserWindow.getAllWindows().length == 0) createWindow();
        });
    }

    /** Базовые IPC-обработчики */
    static function setupIpc():Void {
        IpcMain.on("app:quit", function(_) { App.quit(); });
        IpcMain.on("app:reload", function(_) { if (window != null) window.reload(); });
        IpcMain.on("app:clearCache", function(event) {
            window.webContents.session.clearCache().then(function(_) {
                event.reply("app:clearCache:done");
            });
        });
        // 👇 НОВОЕ: Сборка меню из Renderer
        IpcMain.on("menu:build", function(event, menuData:Dynamic) {
            trace("[AutoWindow] 📥 Received menu data");
            
            var template = processMenuTemplate(cast menuData, event.sender);
            var menu = Menu.buildFromTemplate(template);
            Menu.setApplicationMenu(menu);
            
            trace("[AutoWindow] ✅ Menu set (" + template.length + " top-level items)");
        });

    }

    // Рекурсивно добавляет click-обработчики к пунктам меню
    static function processMenuTemplate(items:Array<Dynamic>, sender:Dynamic):Array<Dynamic> {
        var result = [];
    
        for (item in items) {
            // Пропускаем пустые элементы
            if (item.label == null) continue;
            
            var processed:Dynamic = {
                label: item.label,
                type: item.type != null ? item.type : null,
                enabled: item.enabled != false, // по умолчанию true
                submenu: item.submenu != null ? processMenuTemplate(item.submenu, sender) : null
            };
            
            // Если есть команда — добавляем click-обработчик
            if (item.id != null) {
                var itemId:String = item.id; // замыкание для цикла
                processed.click = function(menuItem:Dynamic, browserWindow:Dynamic, event:Dynamic) {
                    trace("[AutoWindow] 🖱 Click: '" + itemId + "'");
                    sender.send("menu:click", { id: itemId });
                };
            }
            
            result.push(processed);
        }
        
        return result;
    }
}