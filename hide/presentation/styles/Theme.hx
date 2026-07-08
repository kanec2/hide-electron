package hide.presentation.styles;

class Theme {
    public static function applyDarkTheme():Void {
        CssVariables.set("--primary-color", "#6ab0ff");
        CssVariables.set("--background-color", "#1e1e1e");
        CssVariables.set("--text-color", "#d4d4d4");
    }
    public static function applyLightTheme():Void {
        CssVariables.set("--primary-color", "#007acc");
        CssVariables.set("--background-color", "#ffffff");
        CssVariables.set("--text-color", "#333333");
    }
}