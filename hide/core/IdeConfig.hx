package hide.core;

class IdeConfig {
    // Пути
    public static var projectPath(default, set):Null<String> = null;
    public static var appPath:String = "";

    // UI
    public static var theme(default, set):String = "dark";
    public static var layoutConfig:Dynamic;

    // Платформа
    public static var isElectron(default, null):Bool = false;
    public static var isNwjs(default, null):Bool = false;
    public static var isWeb(default, null):Bool = false;

    // Флаги отладки
    public static var debugMode(default, null):Bool = false;
    public static var verboseLogging:Bool = false;

    public static function init():Void {
        // Авто-детект платформы через дефайны
        #if electron
        isElectron = true;
        #elseif nwjs
        isNwjs = true;
        #else
        isWeb = true;
        #end
        
        #if debug
        debugMode = true;
        #end
    }

    static function set_projectPath(v:String):String {
        projectPath = v;
        // Можно добавить валидацию или триггер события
        return v;
    }

    static function set_theme(v:String):String {
        theme = v;
        // Тут можно применить тему к UI
        return v;
    }
}