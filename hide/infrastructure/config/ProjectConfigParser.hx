package hide.infrastructure.config;

import haxe.Json;
class ProjectConfigParser {
    public static function parse(json:String):Dynamic {
        return Json.parse(json);
    }
    public static function stringify(config:Dynamic):String {
        return Json.stringify(config, null, "  ");
    }
}