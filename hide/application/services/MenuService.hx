package hide.application.services;

import hide.application.dto.MenuItem;
import hide.application.dto.ViewDto;
import hide.domain.enums.MenuItemType;
import hide.presentation.config.MenuConfig;
import hx.injection.Service;

class MenuService implements Service {
    private var handlers:Map<String, Void->Void> = [];
    private var menuStructure:Array<MenuItem> = [];

    // ✅ ВОССТАНОВЛЕНО: Поле для хранения недавних проектов
    private var recentProjects:Array<String> = [];

    public function new() {
        // Загружаем меню из Haxe-кода (не из файла!)
        menuStructure = MenuConfig.getBaseMenu();

    }
    // ... остальные методы (onItemClick, trigger, addRecentProject и т.д.)
    // остаются без изменений

    // --- Обработчики событий ---

    public function onItemClick(id: String, handler: Void->Void): Void {
        handlers[id] = handler;
    }

    public function trigger(id: String): Void {
        if (handlers.exists(id)) {
            handlers[id]();
        } else {
            trace("[MenuService] No handler registered for menu item: " + id);
        }
    }

    // --- Геттеры ---

    public function getMenuStructure(): Array<MenuItem> {
        return menuStructure;
    }

    public function getRecentProjects(): Array<String> {
        return recentProjects.copy();
    }
    // ✅ ВОССТАНОВЛЕНО: Метод для добавления View в меню
    public function addViewMenu(view:ViewDto):Void {
        var viewMenu = findMenuItemById("view");
        if (viewMenu == null || viewMenu.children == null) return;
        
        var id = "view." + view.name;
        
        // Проверяем, не добавлен ли уже этот пункт
        for (child in viewMenu.children) {
            if (child.id == id) return;
        }
        
        viewMenu.children.push({
            id: id,
            label: view.label,
            icon: view.icon,
            data: { viewName: view.name }
        });
    }
    // --- Вспомогательные методы ---

    private function findMenuItemById(id: String, ?items: Array<MenuItem>): Null<MenuItem> {
        var searchIn = items != null ? items : menuStructure;
        for (item in searchIn) {
            if (item.id == id) return item;
            if (item.type == Submenu && item.children != null) {
                var found = findMenuItemById(id, item.children);
                if (found != null) return found;
            }
        }
        return null;
    }
}