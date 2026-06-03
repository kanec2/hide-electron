package hide.application.dto;

typedef MenuItem = {
    var id:String;             // Идентификатор пункта меню (например, "view.editor")
    var label:String;          // Отображаемое имя
    var icon:Null<String>;     // Иконка (опционально)
}