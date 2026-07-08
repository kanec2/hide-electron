package shared.extensions;

class StringExt {
    public static function isNullOrEmpty(s:String):Bool {
        return s == null || s.length == 0;
    }
    public static function isNullOrWhiteSpace(s:String):Bool {
        return s == null || StringTools.trim(s).length == 0;
    }
}