package hide.presentation.config;

import hide.application.dto.MenuItem;
import hide.domain.enums.MenuItemType;
/**
 * Статическая конфигурация меню IDE.
 * Изменяется только разработчиками (нужна перекомпиляция).
 * Для динамических элементов (Recent Projects, Views) используются
 * методы MenuService.
 */
class MenuConfig {
    /**
     * Базовая структура меню. 
     * Плагины могут модифицировать этот массив или предоставлять свой.
     */
    public static function getBaseMenu():Array<MenuItem> {
        return [
            // === FILE: команды, НЕ view ===
            {
                id: "file",
                label: "File",
                type: Submenu,
                children: [
                    { id: "project.open", label: "Open Project...", icon: "folder-open" },
                    { id: "project.save", label: "Save Project", icon: "save" },
                    { id: "sep_file_1", label: "", type: Separator },
                    { id: "project.recents", label: "Recent Projects", type: Submenu, children: [] },
                    { id: "sep_file_2", label: "", type: Separator },
                    { id: "project.close", label: "Close Project", enabled: false },
                    { id: "sep_file_3", label: "", type: Separator },
                    { id: "app.exit", label: "Exit" }
                ]
            },
            
            // === VIEW: ПОЛНОСТЬЮ ДИНАМИЧЕСКИЙ! ===
            // children пустой — заполняется из ViewRegistry при старте
            {
                id: "view",
                label: "View",
                type: Submenu,
                children: [
                    // Сюда MenuService.addViewMenu() добавит:
                    //   Scene, Hierarchy, Inspector, Console, ShaderEditor, ...
                    { id: "sep_view_1", label: "", type: Separator },
                    { id: "view.fullscreen", label: "Toggle Fullscreen", icon: "expand", shortcut: "F11" }
                ]
            },
            
            // === LAYOUT: команды, НЕ view ===
            {
                id: "layout",
                label: "Layout",
                type: Submenu,
                children: [
                    { id: "layout.save", label: "Save Layout" },
                    { id: "layout.reset", label: "Reset Layout" }
                ]
            },
            
            // === HELP: команды, НЕ view ===
            {
                id: "help",
                label: "Help",
                type: Submenu,
                children: [
                    { id: "help.about", label: "About HIDE IDE" }
                ]
            }
        ];
    }
}