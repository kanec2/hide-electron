package shared.types;

/**
Массив, который гарантированно содержит хотя бы один элемент
*/
abstract NonEmptyArray<T>(Array<T>) {
    public function new(arr:Array<T>) {
    if (arr == null || arr.length == 0) {
        throw "NonEmptyArray cannot be empty";
    }
        this = arr;
    }
    public function first():T {
        return this[0];
    }
    public function length():Int {
        return this.length;
    }
}