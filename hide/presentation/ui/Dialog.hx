package hide.presentation.ui;

class Dialog {
    public static function alert(message:String):Void {
        js.Browser.window.alert(message);
    }
    public static function confirm(message:String):Bool {
        return js.Browser.window.confirm(message);
    }

    public static function prompt(message:String, ?defaultValue:String):Null<String> {
        return js.Browser.window.prompt(message, defaultValue);
    }
}