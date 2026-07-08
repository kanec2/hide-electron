package hide.presentation.styles;

class CssVariables {
    public static inline var PRIMARY_COLOR:String = "--primary-color";
    public static inline var BACKGROUND_COLOR:String = "--background-color";
    public static inline var TEXT_COLOR:String = "--text-color";
    public static function set(name:String, value:String):Void {
        js.Browser.document.documentElement.style.setProperty(name, value);
    }

    public static function get(name:String):String {
        return js.Browser.document.documentElement.style.getPropertyValue(name);
    }
}