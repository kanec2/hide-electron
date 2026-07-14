// hide/shared/utils/ObjectUtils.hx
package hide.shared.utils;

class ObjectUtils {
    /**
     * Создает новый объект, объединяя поля из source и overrides.
     * Поля из overrides имеют приоритет.
     */
    public static inline function merge<T>(source:T, overrides:Dynamic):T {
        var result:Dynamic = Reflect.copy(source);
        for (field in Reflect.fields(overrides)) {
            Reflect.setField(result, field, Reflect.field(overrides, field));
        }
        return cast result;
    }
}