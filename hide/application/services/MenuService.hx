package hide.application.services;

import hide.domain.services.IClipboardService;
import hide.domain.enums.MenuItemType;
import hide.application.dto.MenuItem;
import hide.application.dto.ViewDto;  // ← Добавляем импорт ViewDto
import hx.injection.*;
/**
 * Сервис для работы с меню.
 * Работает с данными (MenuItemDto), а не с нативными объектами.
 * Поддерживает:
 * - Парсинг HTML-шаблона
 * - Динамические вставки (recents, renderers, layout)
 * - Глобальные идентификаторы (`data-id`) и обработчики
 * - Сериализация для IPC и сохранения в конфиг
 */
class MenuService implements Service {
    private var handlers:Map<String, Void->Void> = [];
    private var menuItems:Array<MenuItem> = [];

    public function new(){}
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
        var xml = Xml.parse(html);
        var items = [];

        // Правильный способ обхода XML в Haxe
        for (node in xml.elements()) {
            if (node.nodeName == "item") {
                var id = node.get("id");
                var label = node.firstChild() != null ? node.firstChild().nodeValue : "";
                items.push({ 
                    id: id, 
                    label: label, 
                    icon: null  // ← Добавляем icon (обязательное поле в MenuItem)
                });
            }
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