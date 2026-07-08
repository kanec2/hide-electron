package shared.extensions;

class ArrayExt {
    public static function find<T>(arr:Array<T>, predicate:T->Bool):Null<T> {
        for (item in arr) {
            if (predicate(item)) return item;
        }
        return null;
    }
    public static function remove<T>(arr:Array<T>, item:T):Bool {
        var index = arr.indexOf(item);
        if (index >= 0) {
            arr.splice(index, 1);
            return true;
        }
        return false;
    }
}