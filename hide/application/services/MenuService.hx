package hide.application.services;

import hide.domain.services.IClipboardService;
import hide.domain.enums.MenuItemType;
import hide.application.dto.MenuItemDto;

/**
 * Сервис для работы с меню.
 * Работает с данными (MenuItemDto), а не с нативными объектами.
 * Поддерживает:
 * - Парсинг HTML-шаблона
 * - Динамические вставки (recents, renderers, layout)
 * - Глобальные идентификаторы (`data-id`) и обработчики
 * - Сериализация для IPC и сохранения в конфиг
 */
class MenuService {
    private var handlers:Map<String, Void->Void> = [];
    private var menuItems:Array<MenuItem> = [];

    public function onItemClick(id:String, handler:Void->Void):Void {
        handlers[id] = handler;
    }

    public function trigger(id:String):Void {
        if (handlers.exists(id)) {
            handlers[id]();
        } else {
            trace("Unknown menu item: $id");
        }
    }

    public function buildFromHtml(html:String):MenuTemplate {
        var dom = new haxe.xml.Fast(Xml.parse(html));
        var items = [];

        for (item in dom.node.querySelectorAll("item")) {
            var id = item.att.id;
            var label = item.node.firstChild().data;
            items.push({ id: id, label: label });
        }

        return { items: items };
    }

    public function addItem(id:String, label:String, ?icon:String):Void {
    menuItems.push({ id: id, label: label, icon: icon });
}

    public function addViewMenu(view:ViewDto):Void {
        var id = "view.${view.name}";
        addItem(id, view.label, view.icon);
        // Можно добавить иконку, подменю и т.д.
    }

    public function getMenuItems():Array<MenuItem> {
        return menuItems.copy();
    }
}

// --- DTO & Config ---

typedef MenuTemplate = {
    var items:Array<MenuItem>;
}
typedef MenuConfig = {
    var recents:Array<String>;
    var renderers:Array<String>;
    var layouts:Array<String>;
    var onOpenRecent:String->Void;
}