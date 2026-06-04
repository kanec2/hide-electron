// hide/application/services/PluginRegistry.hx

package hide.application.services;

import hide.domain.services.IPlugin;

/**
 * Хранилище активных плагинов.
 * Используется для управления плагинами (enable/disable, reload).
 */
class PluginRegistry {
    private var plugins:Map<String, IPlugin> = [];

    public function add(name:String, plugin:IPlugin):Void {
        if (plugins.exists(name)) throw "Plugin $name already exists";
        plugins.set(name, plugin);
    }

    public function get(name:String):Null<IPlugin> {
        return plugins.get(name);
    }

    public function remove(name:String):Bool {
        return plugins.remove(name);
    }

    public function all():Array<IPlugin> {
        return [for (p in plugins) p];
    }

    public function count():Int {
        return plugins.length;
    }
}