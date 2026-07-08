package hide.domain.entities;

/**
Конфигурация layout'а (упрощённая версия)
*/
class LayoutConfig {
    public final name:String;
    public final data:Dynamic;
    public function new(name:String, data:Dynamic) {
        this.name = name;
        this.data = data;
    }
}