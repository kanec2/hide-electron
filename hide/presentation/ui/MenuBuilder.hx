package hide.presentation.ui;

import hide.application.dto.MenuItem;
import hide.domain.enums.MenuItemType;
import js.html.Element;

class MenuBuilder {
    /**
     * Строит корневой элемент меню (горизонтальная панель)
     */
    public static function build(items:Array<MenuItem>):Element {
        var ul = js.Browser.document.createElement("ul");
        ul.className = "main-menu-bar";
        
        for (item in items) {
            ul.appendChild(createMenuItem(item));
        }
        
        return ul;
    }

    /**
     * Рекурсивно создает элемент списка <li> и его содержимое
     */
    private static function createMenuItem(item:MenuItem):Element {
        var li = js.Browser.document.createElement("li");
        li.className = "menu-item";
        
        if (item.enabled == false) {
            li.className += " disabled";
        }

        // 1. Если это разделитель
        if (item.type == Separator) {
            li.className += " separator";
            return li;
        }

        // 2. Создаем кликабельный элемент (кнопку)
        var btn = js.Browser.document.createElement("button");
        btn.className = "menu-button";
        btn.setAttribute("data-menu-id", item.id); // Ключ для делегирования событий
        
        // Добавляем иконку, если она есть (предполагаем использование FontAwesome или аналога)
        var iconHtml = item.icon != null ? '<i class="fa fa-${item.icon}"></i>' : '';
        var shortcutHtml = item.shortcut != null ? '<span class="menu-shortcut">${item.shortcut}</span>' : '';

        // Собираем всё вместе: Иконка + Текст + (Хоткей справа)
        btn.innerHTML = iconHtml + ' <span style="flex:1">${item.label}</span> ' + shortcutHtml;
        li.appendChild(btn);

        // 3. Если это подменю, рекурсивно строим его дочерние элементы
        if (item.type == Submenu && item.children != null && item.children.length > 0) {
            li.className += " has-submenu";
            var subUl = js.Browser.document.createElement("ul");
            subUl.className = "submenu";
            
            for (child in item.children) {
                subUl.appendChild(createMenuItem(child));
            }
            
            li.appendChild(subUl);
        }

        return li;
    }
}