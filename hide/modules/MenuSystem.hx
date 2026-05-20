package hide.modules;

import hide.core.Ide;

typedef MenuItemDef = {
    var label:String;
    @:optional var id:Null<String>;      // Команда (из class/onclick/id)
    @:optional var type:Null<String>;    // "checkbox", "radio", "separator"
    @:optional var enabled:Bool;         // По умолчанию true
    @:optional var submenu:Null<Array<MenuItemDef>>;
}

class MenuSystem {
    var ide:Ide;
    var commands:Map<String, Void->Void>;

    public function new(ide:Ide) {
        this.ide = ide;
        commands = new Map();
    }

    /**
     * Загружает меню из <xml id="mainmenu"> и отправляет в Main Process
     */
    public function loadFromXml():Void {
        var buildMenu = function() {
            var xmlEl = js.Browser.document.getElementById("mainmenu");
            if (xmlEl == null) {
                trace("[MenuSystem] ⚠️ mainmenu XML not found!");
                return;
            }

            var menuData:Array<MenuItemDef> = [];
            for (i in 0...xmlEl.children.length) {
                var item = parseMenuItem(cast xmlEl.children[i]);
                if (item != null) menuData.push(item);
            }

            trace("[MenuSystem] 📤 Sending menu to Main: " + haxe.Json.stringify(menuData));
            ide.getBackend().createMenu(menuData);
            ide.getBackend().onMenuClick(handleCommand);
        };

        // Проверка readyState для надёжности
        if (js.Browser.document.readyState == "complete" || js.Browser.document.readyState == "interactive") {
            buildMenu();
        } else {
            js.Browser.document.addEventListener("DOMContentLoaded", function(_) buildMenu());
        }
    }

    /**
     * Регистрация команды
     */
    public function registerCommand(id:String, handler:Void->Void):Void {
        commands.set(id, handler);
        trace("[MenuSystem] ✅ Registered: " + id);
    }

    /**
     * Обработчик клика из Main Process
     */
    function handleCommand(id:String):Void {
        trace("[MenuSystem] 🔍 Command requested: '" + id + "'");
        
        if (commands.exists(id)) {
            trace("[MenuSystem] ▶ Executing: " + id);
            commands.get(id)();
        } else {
            trace("[MenuSystem] ❌ Unknown command: '" + id + "'");
            //trace("[MenuSystem]    Available: " + commands.keys().join(", "));
        }
    }

    /**
     * Парсинг элемента меню — ключевая функция!
     */
    function parseMenuItem(el:js.html.Element):Null<MenuItemDef> {
        var tag = el.tagName.toLowerCase();
        
        // Пропускаем служебные теги
        if (tag == "xml" || tag == "content") return null;
        
        // Сепаратор
        if (tag == "separator") {
            return { label: "", type: "separator" };
        }
        
        // <div> внутри меню — контейнер для динамических пунктов, не парсим
        if (tag == "div") {
            return { 
                label: el.getAttribute("label") != null ? el.getAttribute("label") : "Section",
                enabled: false,
                submenu: [] // Пустое подменю — позже заполнится динамически
            };
        }
        
        // Основной пункт меню
        var label = el.getAttribute("label");
        if (label == null) return null; // Пропускаем элементы без текста
        
        // === Извлечение команды: приоритет class → onclick → id → command ===
        var cmd:Null<String> = null;
        
        if (el.getAttribute("class") != null) {
            cmd = el.getAttribute("class");
        } else if (el.getAttribute("onclick") != null) {
            cmd = el.getAttribute("onclick");
        } else if (el.getAttribute("id") != null) {
            cmd = el.getAttribute("id");
        } else if (el.getAttribute("command") != null) {
            cmd = el.getAttribute("command");
        }
        
        // Очистка команды: "onExit()" → "onExit", "  exit  " → "exit"
        if (cmd != null) {
            cmd = StringTools.replace(cmd, "()", "");
        }
        
        // Тип элемента
        var type = el.getAttribute("type"); // checkbox, radio
        var disabled = el.getAttribute("disabled") != null;
        
        var item:MenuItemDef = {
            label: label,
            id: cmd,
            type: type,
            enabled: !disabled
        };
        
        // Рекурсивный парсинг подменю
        if (el.children != null && el.children.length > 0) {
            var submenu = [];
            for (i in 0...el.children.length) {
                var child = parseMenuItem(cast el.children[i]);
                if (child != null) submenu.push(child);
            }
            if (submenu.length > 0) {
                item.submenu = submenu;
            }
        }
        
        trace("[MenuSystem] Parsed: '" + label + "' → id='" + item.id + "'");
        return item;
    }
}