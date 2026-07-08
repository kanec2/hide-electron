package hide.domain.entities;

/**
Настройки пользователя
*/
class UserSettings {
    public var theme:String;
    public var fontSize:Int;
    public var autoSave:Bool;
    public function new() {
        this.theme = "dark";
        this.fontSize = 14;
        this.autoSave = true;
    }
}