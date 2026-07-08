package shared.utils;

import haxe.Json;
class JsonUtils {
    public static function safeParse(json:String):Null<Dynamic> {
        try {
            return Json.parse(json);
        } catch (e:Dynamic) {
            return null;
        }
    }   
    public static function safeStringify(obj:Dynamic):String {
        try {
            return Json.stringify(obj);
        } catch (e:Dynamic) {
            return "{}";
        }
    }
}