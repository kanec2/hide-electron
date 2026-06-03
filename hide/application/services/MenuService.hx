package hide.application.services;

import hide.domain.services.IClipboardService;
import hide.domain.enums.MenuItemType;
import hide.application.dto.MenuItemDto;

/**
 * Сервис для работы с меню.
 * Работает с данными (MenuItemDto), а не с нативными объектами.
 */
class MenuService {
    private var clipboard:IClipboardService;
    
    public function new(clipboard:IClipboardService) {
        this.clipboard = clipboard;
    }
    
    /**
     * Строит шаблон меню из HTML-строки.
     * Возвращает данные, которые можно:
     * - Сериализовать для IPC
     * - Передать в UI для рендеринга
     * - Сохранить в конфиг
     */
    public function buildFromHtml(html:String):Array<MenuItemDto> {
        var template:Array<MenuItemDto> = [];
        var root = new Element(html);
        
        for (child in root.children().elements()) {
            var item = parseMenuItem(child);
            if (item != null) template.push(item);
        }
        
        return template;
    }
    
    private function parseMenuItem(el:Element):Null<MenuItemDto> {
        var node = el.get(0);
        
        return switch node.nodeName.toLowerCase() {
            case "menu":
                var submenu:Null<Array<MenuItemDto>> = null;
                if (el.children().length > 0) {
                    submenu = [for (c in el.children().elements()) parseMenuItem(c)].filter(i -> i != null);
                }
                
                {
                    label: el.attr("label") ?? "???",
                    type: parseType(el.attr("type")),
                    checked: el.prop("checked") || el.attr("checked") == "checked",
                    enabled: el.attr("disabled") != "disabled",
                    submenu: submenu,
                    id: el.attr("data-id") // Опциональный ID для маппинга кликов
                };
                
            case "separator":
                { type: Separator };
                
            case _:
                null; // Игнорируем неизвестные теги
        }
    }
    
    private function parseType(?t:String):MenuItemType {
        return switch t {
            case "checkbox": Checkbox;
            case "separator": Separator;
            case _: Normal;
        }
    }
    
    /**
     * Копирует данные в буфер обмена.
     */
    public function setClipboard(data:Dynamic, ?type:String = "text"):Void {
        clipboard.setText(Std.string(data), type);
    }
    
    public function getClipboard(?type:String = "text"):String {
        return clipboard.getText(type);
    }
}