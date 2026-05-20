package hide.core;

import hide.modules.WindowManager;
import js.node.Url;
import hide.modules.MenuSystem;
import js.Browser.document;
import js.Browser.window;
import js.Node.process;
import js.node.ChildProcess;
// Пока не импортируем модули — заглушки создадим ниже
// import hide.modules.*;

class Ide {
    public static var inst(default, null):Ide;

    // === Модули (объявляем как var, а не свойства с доступом) ===
    public var windowManager:WindowManager; // Пока Dynamic, позже типизируем
    public var menuSystem:MenuSystem;
    public var fileSystem:Dynamic;
    public var projectManager:Dynamic;
    public var uiLayout:Dynamic;
    public var searchNav:Dynamic;

    // === Бэкенд ===
    private var backend:IIdeBackend;

    // === Состояние ===
    public var isInitialized(default, null):Bool = false;
    public var currentProject:Dynamic;

    public function new() {
        inst = this;
        
        // 1. Инициализация конфига
        IdeConfig.init();
        
        // 2. Создание бэкенда
        backend = createBackend();
        backend.init();
        
        // 3. Сохранение appPath
        IdeConfig.appPath = backend.getAppPath();
    }

    // В классе Ide, после полей и конструктора:

    /**
     * Открывает компонент (суб-вью)
     * Вызывается из меню и других частей кода.
     * @param componentName Полное имя класса, например "hide.view.FileBrowser"
     * @param state JSON-состояние компонента (опционально)
     * @param ?position Позиция в интерфейсе (content_left и т.д.) — пока игнорируется
     */
    public function open(componentName:String, ?state:Dynamic, ?position:String):Void {
        trace("[Ide] 🪟 Opening component: " + componentName);
        
        // Формируем URL с параметрами, как в оригинальном NW.js-коде
        var url = "app.html?subView=" + componentName;
        
        // Добавляем состояние, если передано
        if (state != null) {
            var stateJson = haxe.Json.stringify(state);
            url += "&state=" + Url.format(stateJson);
        }
        
        // Добавляем позицию, если передана
        if (position != null) {
            url += "&pos=" + position;
        }
        
        // Отправляем запрос на открытие окна через бэкенд
        // WindowManager.openWindow() уже реализован и работает
        backend.openWindow(url, {
            title: componentName.split(".").pop(), // Короткое имя для заголовка
            width: 800,
            height: 600,
            id: componentName
        }, componentName);
        
        trace("[Ide] ✅ Window request sent: " + url);
    }

    static function createBackend():IIdeBackend {
        #if electron
        return new hide.electron.ElectronBackend(); // 👈 Требует создания файла
        #elseif nwjs
        return new hide.nwjs.NwjsBackend();
        #else
        return new hide.core.FallbackBackend();
        #end
    }

    // === Публичный API ===
    public function getBackend():IIdeBackend return backend;
    
    public function getModule(name:String):Dynamic {
        return switch name {
            case "windowManager": windowManager;
            case "menuSystem": menuSystem;
            case "fileSystem": fileSystem;
            case "projectManager": projectManager;
            case "uiLayout": uiLayout;
            case "searchNav": searchNav;
            case _: null;
        }
    }

    // === Точка входа ===
    public function init():Void {
        if (isInitialized) return;
        
        trace("🚀 Hide IDE initializing...");
        // 1. Создаём модули
        windowManager = new WindowManager(this);
        menuSystem = new MenuSystem(this);

        // 2. Загружаем меню из XML
        menuSystem.loadFromXml();

        // 3. Регистрируем команды (примеры)
        // === Project menu ===
        menuSystem.registerCommand("exit", function() { 
            trace("🚪 Exit"); 
            getBackend().quit(); 
        });
        
        menuSystem.registerCommand("open", function() { 
            trace("📂 Open project"); 
            // TODO: getBackend().chooseDirectory(...)
        });
        
        menuSystem.registerCommand("clear", function() { 
            trace("🗑 Clear recents"); 
            // TODO: логика очистки
        });
        
        menuSystem.registerCommand("clear-local", function() { 
            trace("🧹 Clear local profile"); 
            js.Browser.window.localStorage.clear();
            getBackend().clearCache();
            getBackend().reload();
        });
        
        menuSystem.registerCommand("build-files", function() { 
            trace("🔨 Build files"); 
            // TODO: hrt.impl.BuildTools.buildAllFiles(...)
        });

        // === View menu ===
        menuSystem.registerCommand("debug", function() { 
            trace("🐛 DevTools"); 
            getBackend().showDevTools(); 
        });
        
        // Компоненты с атрибутом [component]
        menuSystem.registerCommand("hide.view.FileBrowser", function() { 
            open("hide.view.FileBrowser", {}); 
        });
        menuSystem.registerCommand("hide.view.DomkitStudio", function() { 
            open("hide.view.DomkitStudio", {}); 
        });
        menuSystem.registerCommand("hide.view.About", function() { 
            open("hide.view.About", {}); 
        });
        menuSystem.registerCommand("hide.view.Gym", function() { 
            open("hide.view.Gym", {}); 
        });

        // === Database menu ===
        menuSystem.registerCommand("dbView", function() { 
            //open("hide.view.CdbTable", {}); 
            // Открываем просто app.html без параметров
            open("app.html", {});  // Или даже "https://example.com" для теста
        });
        menuSystem.registerCommand("dbCustom", function() { 
            trace("⚙️ DB Custom Types"); 
        });
        menuSystem.registerCommand("dbCompress", function() { 
            trace("🗜 DB Compress toggle"); 
        });
        menuSystem.registerCommand("dbExport", function() { 
            trace("📤 DB Export"); 
        });
        menuSystem.registerCommand("dbImport", function() { 
            trace("📥 DB Import"); 
        });
        menuSystem.registerCommand("dbProofread", function() { 
            trace("👁 DB Proofread toggle"); 
        });

        // === Layout menu ===
        menuSystem.registerCommand("save", function() { 
            trace("💾 Save layout"); 
        });
        menuSystem.registerCommand("saveas", function() { 
            trace("💾 Save As..."); 
        });
        menuSystem.registerCommand("autosave", function() { 
            trace("🔄 Autosave toggle"); 
        });

        // === Settings menu ===
        menuSystem.registerCommand("user-settings", function() { 
            trace("⚙️ User settings"); 
        });
        menuSystem.registerCommand("project-settings", function() { 
            trace("⚙️ Project settings"); 
        });


        // Добавьте остальные onclick из вашего app.xml...

        // Пока не создаём модули — только заглушки
        // Позже раскомментируем:
        // uiLayout = new UiLayout(this);
        // menuSystem = new MenuSystem(this);
        // ...
        
        // Регистрация реальных Haxe-классов для GoldenLayout
        // (выполняется после загрузки всех модулей)
        // Стало (правильно для JS-таргета):
        #if electron
        //js.Browser.window.setTimeout(registerGoldenLayoutComponents, 100);
        #elseif heaps
        // Если когда-нибудь будете компилировать под нативный Heaps:
        // hxd.Timer.addTimeListener(0.1, function(_) registerGoldenLayoutComponents());
        #end
        registerGoldenLayoutComponents();
        isInitialized = true;
        trace("✅ Hide IDE ready (stub mode).");
        setText('system-version',"✅ Hide IDE ready (stub mode).");
    }

    /**
     * Регистрация компонентов в GoldenLayout
     * Вызывается после инициализации UI
     */
    function registerGoldenLayoutComponents():Void {
        var wm = windowManager;
        
        // Простая проверка без цикла — если не готово, просто выходим
        // (GoldenLayout сам вызовет setGoldenLayout, когда будет готов)
        if (wm == null || wm.goldenLayout == null) {
            trace("[Ide] ⏳ GoldenLayout not ready yet (will register later)");
            return;
        }
        
        trace("[Ide] ✅ GoldenLayout connected, registering components...");
        
        // Регистрируем компоненты ПРЯМО в goldenLayout
        // (WindowManager хранит ссылку, так что это работает)
        wm.goldenLayout.registerComponent("hide.view.CdbTable", function(container:Dynamic, state:Dynamic) {
            trace("[GL] Creating CdbTable panel");
            container.getElement().html('<div class="cdb-table">CdbTable placeholder</div>');
        });
        
        wm.goldenLayout.registerComponent("hide.view.FileBrowser", function(container:Dynamic, state:Dynamic) {
            trace("[GL] Creating FileBrowser panel");
            container.getElement().html('<div class="file-browser">FileBrowser placeholder</div>');
        });
        
        wm.goldenLayout.registerComponent("hide.view.DomkitStudio", function(container:Dynamic, state:Dynamic) {
            trace("[GL] Creating DomkitStudio panel");
            container.getElement().html('<div>DomkitStudio placeholder</div>');
        });
        
        wm.goldenLayout.registerComponent("hide.view.About", function(container:Dynamic, state:Dynamic) {
            trace("[GL] Creating About panel");
            container.getElement().html('<div>About Hide IDE</div>');
        });
        
        wm.goldenLayout.registerComponent("hide.view.Gym", function(container:Dynamic, state:Dynamic) {
            trace("[GL] Creating Gym panel");
            container.getElement().html('<div>Editor Gym placeholder</div>');
        });
    }

    static inline function setText(id:String, text:String) {
		document.getElementById(id).textContent = text;
	}

    // 👇 НОВОЕ: Точка входа для JS-рантайма (Renderer Process)
    public static function main():Void {
        window.onload = () -> {

            trace("🌐 Renderer process starting...");
            setText('system-version',"🌐 Renderer process starting...");
            var app = new Ide();
            app.init();
            
        }
    }
}