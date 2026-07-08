package shared.utils;

class AsyncUtils {
    public static function delay(callback:Void->Void, ms:Int):Void {
        haxe.Timer.delay(callback, ms);
    }
    public static function nextTick(callback:Void->Void):Void {
        haxe.Timer.delay(callback, 0);
    }
}