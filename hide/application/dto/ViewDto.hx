// hide/application/dto/ViewDto.hx

package hide.application.dto;

typedef ViewDto = {
    var name:String;           // Идентификатор (для componentName в GoldenLayout)
    var label:String;          // Отображаемое имя в меню (например, "Редактор")
    var description:String;    // Описание (для tooltip, справки)
    var icon:Null<String>;     // Иконка (например, "fa-code" или SVG-код)
    var defaultState:Dynamic;  // Начальное состояние (например, { path: "..." })
}