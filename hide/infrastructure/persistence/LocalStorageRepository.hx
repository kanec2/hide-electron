package hide.infrastructure.persistence;

class LocalStorageRepository {
    public function new() {}
    public function get(key:String):Null<String> {
        return js.Browser.window.localStorage.getItem(key);
    }

    public function set(key:String, value:String):Void {
        js.Browser.window.localStorage.setItem(key, value);
    }

    public function remove(key:String):Void {
        js.Browser.window.localStorage.removeItem(key);
    }
}