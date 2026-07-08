package shared.utils;

class PathUtils {
    public static function join(parts:Array<String>):String {
        return parts.join("/");
    }
    public static function getExtension(path:String):String {
        var parts = path.split(".");
        return parts.length > 1 ? parts[parts.length - 1] : "";
    }

    public static function getFileName(path:String):String {
        var parts = path.split("/");
        return parts[parts.length - 1];
    }

    public static function getDirectory(path:String):String {
        var parts = path.split("/");
        parts.pop();
        return parts.join("/");
    }
}