// src/main/external/Lowdb.hx
package src.main.external;  // ✅ Точно соответствует пути!

import js.node.Fs;

/**
 * Синхронный JSON-адаптер для lowdb v5.
 * Находится в подмодуле 'lowdb/node'
 */
@:jsRequire("lowdb/node", "JSONFileSync")
extern class JSONFileSync<T> {
    function new(filename:String, ?options:Dynamic):Void;
}


/**
 * Основной класс синхронной базы данных lowdb v5.
 */
@:jsRequire("lowdb", "LowSync")
extern class LowSync<T> {
    function new(adapter:JSONFileSync<T>):Void;
    
    function read():Void;
    function write():Void;
    
    /**
     * Прямой доступ к данным. В v5 мы работаем с db.data напрямую.
     */
    var data:T;
}