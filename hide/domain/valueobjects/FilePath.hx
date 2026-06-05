// hide/domain/valueobjects/FilePath.hx (Рекомендуемая реализация)
package hide.domain.valueobjects;

@:forward
abstract FilePath(String) from String to String {
    public function new(path:String) {
        if (path == null || path.trim() == "") {
            throw "FilePath cannot be null or empty";
        }
        // Здесь можно добавить нормализацию: path = path.replace("\\", "/");
        this = path;
    }

    public function isValid():Bool {
        return this.length > 0; // Упрощенная проверка
    }
}