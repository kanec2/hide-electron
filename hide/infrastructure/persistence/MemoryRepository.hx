package hide.infrastructure.persistence;

class MemoryRepository<T> {
    private var data:Map<String, T>;
    public function new() {
        data = new Map();
    }

    public function get(key:String):Null<T> {
        return data.get(key);
    }

    public function set(key:String, value:T):Void {
        data.set(key, value);
    }

    public function remove(key:String):Bool {
        return data.remove(key);
    }

    public function clear():Void {
        data = new Map();
    }
}