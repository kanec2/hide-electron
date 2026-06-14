package hide.domain.entities;

import hide.domain.enums.ResourceType;

/**
 * Сущность ресурса (файл, текстура, модель и т.д.).
 * Пока содержит минимум полей, необходимых для компиляции Project.hx.
 */
class Resource {
    public final id:String;
    public final type:ResourceType;
    public final path:String; // Путь относительно корня проекта

    public function new(id:String, type:ResourceType, path:String) {
        this.id = id;
        this.type = type;
        this.path = path;
    }
}