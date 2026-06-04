// hide/application/services/PluginFactory.hx

package hide.application.services;

import hide.domain.services.IPlugin;
import haxe.macro.Expr;

/**
 * Фабрика плагинов.
 * Загружает плагины динамически, используя рефлексию.
 */
class PluginFactory {
    public static function load(className:String):Null<IPlugin> {
        try {
            var pluginClass = Type.resolveClass(className);
            if (pluginClass == null) return null;

            var plugin = Type.createInstance(pluginClass, []);
            if (!Std.is(plugin, IPlugin)) return null;

            return cast plugin;
        } catch (e:Dynamic) {
            trace("Failed to load plugin: $className - ${e}");
            return null;
        }
    }
}