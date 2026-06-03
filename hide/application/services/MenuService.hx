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
    private var clipboard:IClipboardService;

    // === Кэш обработчиков по ID ===
    private var _clickHandlers:Map<String, Void->Void> = [];

    // === Состояние ===
    private var recentProjects:Array<String> = [];

    // === Конструктор ===
    public function new(clipboard:IClipboardService) {
        this.clipboard = clipboard;
    }

    // === Публичное API ===

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

    /**
     * Строит меню из шаблона + динамических данных (конфиг).
     * Поддерживает:
     * - `project.recents`: заменяет `.recents` на список проектов
     * - `project.renderers`: чекбоксы выбора рендерера
     * - `layout`: список layout-ов
     */
    public function buildFromTemplate(
        baseTemplate:Array<MenuItemDto>,
        config:MenuConfig
    ):Array<MenuItemDto> {
        // Клонируем шаблон, чтобы не мутировать оригинал
        var template = [for (item in baseTemplate) cloneMenuItem(item)];

        // Применяем динамические вставки
        for (item in template) {
            if (item.id == "project.recents" && config.recents.length > 0) {
                item.submenu = [for (p in config.recents) {
                    label: p,
                    type: Normal,
                    id: "project.recents.${p}",
                    onclick: config.onOpenRecent != null ? config.onOpenRecent(p) : null
                }];
            }
        }

        return template;
    }

    /**
     * Регистрирует глобальный обработчик для `data-id`.
     * Вызывается в UI-рендере (например, в `MenuRenderer`).
     */
    public function onItemClick(id:String, callback:Void->Void):Void {
        _clickHandlers[id] = callback;
    }

    /**
     * Вызывает обработчик по ID (вызывается из UI при клике).
     */
    public function triggerItemClick(id:String):Void {
        if (h = _clickHandlers[id]) h();
    }

    // --- Recents management ---
    public function clearRecentProjects():Void {
        recentProjects = [];
    }

    public function addRecentProject(path:String):Void {
        recentProjects.remove(path);
        recentProjects.unshift(path);
        // Ограничим 10 последними
        if (recentProjects.length > 10) recentProjects.pop();
    }

    public function getRecentProjects():Array<String> return recentProjects.copy();

    // --- Вспомогательные методы ---
    private function cloneMenuItem(item:MenuItemDto):MenuItemDto {
        return {
            label: item.label,
            type: item.type,
            checked: item.checked,
            enabled: item.enabled,
            submenu: item.submenu != null ? [for (sub in item.submenu) cloneMenuItem(sub)] : null,
            id: item.id,
            onclick: item.onclick
        };
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

    // === Буфер обмена ===
    public function setClipboard(data:Dynamic, ?type:String = "text"):Void {
        clipboard.setText(Std.string(data), type);
    }

    public function getClipboard(?type:String = "text"):String {
        return clipboard.getText(type);
    }
}

// --- DTO & Config ---

typedef MenuConfig = {
    var recents:Array<String>;
    var renderers:Array<String>;
    var layouts:Array<String>;
    var onOpenRecent:String->Void;
}