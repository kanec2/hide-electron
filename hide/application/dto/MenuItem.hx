package hide.application.dto;
import hide.domain.enums.MenuItemType;
typedef MenuItem = {
    var id: String;                     // Уникальный ID (например, "project.open")
    var label: String;                  // Отображаемый текст
    var ?type: MenuItemType;             // Тип элемента
    var ?icon: String;                  // Иконка (опционально)
    var ?children: Array<MenuItem>;     // Дочерние элементы (для Submenu)
    var ?enabled: Bool;                 // Доступен ли пункт (по умолчанию true)
    var ?data: Dynamic;                 // Любые дополнительные данные (например, путь к файлу)
    var ?shortcut: String; // <-- ДОБАВЛЯЕМ ЭТО ПОЛЕ (например, "Ctrl+O")
}