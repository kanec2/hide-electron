import electron.main.Menu;
import electron.main.App;
import electron.main.BrowserWindow;
import electron.main.IpcMain;
import electron.main.Dialog;
import electron.IpcMainEvent;
import js.node.Fs;
import js.node.Path;
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
            var pkgPath = Path.join(__dirname, "package.json");
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
            frame: false,
            titleBarStyle: 'hidden',
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false,
                enableRemoteModule: true
            }
        };

        if (cfg.icon != null) opts.icon = Path.join(__dirname, cfg.icon);
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

    /**
     * Рекурсивно создает директорию, если она не существует.
     * Обходит ограничение hxnodejs на параметр { recursive: true }
     */
    static function ensureDirectoryExists(dir:String):Void {
        if (dir == null || dir == "") return;
        if (Fs.existsSync(dir)) return;
        
        // Рекурсивно создаем родительскую директорию
        ensureDirectoryExists(Path.dirname(dir));
        
        // Создаем текущую директорию
        Fs.mkdirSync(dir);
    }

    static function processMenuTemplate(items:Array<Dynamic>, sender:Dynamic):Array<Dynamic> {
        if (items == null) return [];
        
        var result = [];
        for (item in items) {
            // 跳过无效项（但保留 separator）
            if (item.label == null && item.type != "separator") continue;
            
            var processed:Dynamic = {
                label: item.label,
                type: item.type != null ? item.type : null,
                enabled: item.enabled != false, // 默认 true
                submenu: item.submenu != null ? processMenuTemplate(item.submenu, sender) : null
            };
            
            // 如果有 id，说明是可点击的菜单项，注入 click 处理
            if (item.id != null) {
                var itemId:String = item.id; // 闭包捕获当前 id
                processed.click = function(menuItem:Dynamic, browserWindow:Dynamic, event:Dynamic) {
                    trace("[AutoWindow] 🖱 Click: '" + itemId + "'");
                    // 将点击事件发回 Renderer 进程
                    sender.send("menu:click", { id: itemId });
                };
            }
            
            result.push(processed);
        }
        
        return result;
    }
    static function setupIpc():Void {
        // === Базовые команды приложения ===
        IpcMain.on("app:quit", function(event:IpcMainEvent) { 
            App.quit(); 
        });
        
        IpcMain.on("app:reload", function(event:IpcMainEvent) { 
            if (window != null) window.reload(); 
        });

        // === Файловая система (синхронные вызовы через sendSync) ===
        IpcMain.on("fs:exists", function(event:IpcMainEvent, filePath:String) {
            try {
                event.returnValue = Fs.existsSync(filePath);
            } catch (e:Dynamic) {
                event.returnValue = false;
            }
        });

        IpcMain.on("fs:readText", function(event:IpcMainEvent, filePath:String) {
            try {
                if (!Fs.existsSync(filePath)) {
                    event.returnValue = { error: "File not found" };
                } else {
                    var content = Fs.readFileSync(filePath, { encoding: "utf-8" });
                    event.returnValue = { content: content };
                }
            } catch (e:Dynamic) {
                event.returnValue = { error: Std.string(e) };
            }
        });

        IpcMain.on("fs:writeText", function(event:IpcMainEvent, data:Dynamic) {
            try {
                var dir = Path.dirname(data.path);
                if (!Fs.existsSync(dir)) {
                   // Fs.mkdirSync(dir, { recursive: true });
                   ensureDirectoryExists(dir);
                }
                Fs.writeFileSync(data.path, data.content, { encoding: "utf-8" });
                event.returnValue = {};
            } catch (e:Dynamic) {
                event.returnValue = { error: Std.string(e) };
            }
        });

        IpcMain.on("fs:listFiles", function(event:IpcMainEvent, data:Dynamic) {
            try {
                var files:Array<String> = [];
                function scan(dir:String) {
                    var entries = Fs.readdirSync(dir);
                    for (entry in entries) {
                        var fullPath = Path.join(dir, entry);
                        var stat = Fs.statSync(fullPath);
                        if (stat.isDirectory() && data.recursive) {
                            scan(fullPath);
                        } else if (stat.isFile()) {
                            files.push(fullPath);
                        }
                    }
                }
                if (Fs.existsSync(data.path)) {
                    scan(data.path);
                }
                event.returnValue = { files: files };
            } catch (e:Dynamic) {
                event.returnValue = { error: Std.string(e) };
            }
        });

        IpcMain.on("app:getAppDataPath", function(event:IpcMainEvent) {
            event.returnValue = App.getPath("userData");
        });

        // === Диалоги (асинхронные вызовы через invoke) ===
        IpcMain.handle("dialog:showOpen", function(event:Dynamic, options:Dynamic) {
            return Dialog.showOpenDialog(window, options);
        });

        IpcMain.handle("dialog:showSave", function(event:Dynamic, options:Dynamic) {
            return Dialog.showSaveDialog(window, options);
        });

        IpcMain.handle("dialog:showDirectory", function(event:Dynamic, options:Dynamic) {
            options.properties = ["openDirectory", "createDirectory"];
            return Dialog.showOpenDialog(window, options);
        });

        // === Управление окном ===
        IpcMain.on("window:setTitle", function(event:IpcMainEvent, title:String) {
            if (window != null) window.setTitle(title);
            event.returnValue = null;
        });

        IpcMain.on("window:enterFullscreen", function(event:IpcMainEvent) {
            if (window != null) window.setFullScreen(true);
            event.returnValue = null;
        });

        IpcMain.on("window:leaveFullscreen", function(event:IpcMainEvent) {
            if (window != null) window.setFullScreen(false);
            event.returnValue = null;
        });

        // === Меню (существующий код) ===
        IpcMain.on("menu:build", function(event:IpcMainEvent, menuData:Dynamic) {
            trace("[AutoWindow] 📥 Received menu data");
            var template = processMenuTemplate(cast menuData, event.sender);
            var menu = Menu.buildFromTemplate(template);
            Menu.setApplicationMenu(menu);
            trace("[AutoWindow] ✅ Menu set (" + template.length + " top-level items)");
        });

        // === Открытие окон ===
        IpcMain.on("window:open", function(event:IpcMainEvent, data:Dynamic) {
            var url:String = data.url;
            
            if (url.indexOf("?subView=") != -1) {
                trace("[AutoWindow] ⚠️ Sub-view request: " + url);
                event.sender.send("window:open:subview", { url: url });
                return;
            }
            
            var opts:Dynamic = {
                width: data.options.width != null ? data.options.width : 800,
                height: data.options.height != null ? data.options.height : 600,
                title: data.options.title != null ? data.options.title : "Hide",
                parent: window,
                webPreferences: {
                    nodeIntegration: true,
                    contextIsolation: false
                }
            };
            
            var child = new BrowserWindow(opts);
            child.loadFile(url);
        });
    }
}

/* === JS ===
// main.js (Electron Main Process)
const { app, ipcMain, dialog } = require('electron');
const fs = require('fs');

// Dialog handlers
ipcMain.handle('dialog:showOpen', async (event, options) => {
    return await dialog.showOpenDialog(options);
});

ipcMain.handle('dialog:showSave', async (event, options) => {
    return await dialog.showSaveDialog(options);
});

ipcMain.handle('dialog:showDirectory', async (event, options) => {
    return await dialog.showOpenDialog(options);
});

// File system handlers
ipcMain.handle('fs:readText', async (event, path) => {
    try {
        const content = fs.readFileSync(path, 'utf-8');
        return { content };
    } catch (err) {
        return { error: err.message };
    }
});

ipcMain.handle('fs:writeText', async (event, path, content) => {
    try {
        fs.writeFileSync(path, content, 'utf-8');
        return { success: true };
    } catch (err) {
        return { error: err.message };
    }
});
*/