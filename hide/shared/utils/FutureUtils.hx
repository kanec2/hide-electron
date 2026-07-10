package hide.shared.utils;

import tink.core.Future;
import tink.core.Outcome;
import js.lib.Promise;
using tink.CoreApi;
/**
 * Утилиты для конвертации tink Future в js.lib.Promise.
 * Нужны для интеграции с Monaco Editor, который ожидает Promise.
 */
class FutureUtils {
    /**
     * Конвертирует Future<T> в js.lib.Promise<T>.
     * Используется для интеграции с API, которые ожидают Promise (например, Monaco).
     */
    public static function toPromise<T>(future:Future<T>):Promise<T> {
        return new Promise(function(resolve, reject) {
            future.handle(function(result:T) {
                resolve(result);
            });
        });
    }
    
    /**
     * Конвертирует Future<Outcome<T, Error>> в js.lib.Promise<T>.
     * При Failure — отклоняет Promise с ошибкой.
     */
    public static function outcomeToPromise<T>(future:Future<Outcome<T, tink.core.Error>>):Promise<T> {
        return new Promise(function(resolve, reject) {
            future.handle(function(outcome:Outcome<T, tink.core.Error>) {
                switch (outcome) {
                    case Success(value):
                        resolve(value);
                    case Failure(error):
                        reject(error);
                }
            });
        });
    }
}