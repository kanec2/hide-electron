package hide.application.services;

import hide.shared.types.IEventBus;
import hide.domain.services.IPlugin;
import hide.domain.services.IFileSystem;
import hide.shared.types.FilePath;
import haxe.Json;

class PluginManager {
    private var registry:PluginRegistry;
    private var viewRegistry:ViewRegistry;
    private var eventBus:IEventBus;
    private var fileSystem:IFileSystem;
    private var configPath:FilePath;
    private var config:PluginsConfig;

    public function new(
        registry:PluginRegistry,
        viewRegistry:ViewRegistry,
        eventBus:IEventBus,
        fileSystem:IFileSystem,
        ?configPathStr:String = "plugins.json"
    ) {
        this.registry = registry;
        this.viewRegistry = viewRegistry;
        this.eventBus = eventBus;
        this.fileSystem = fileSystem;
        this.configPath = new FilePath(configPathStr);
        loadConfig();
    }

    private function loadConfig():Void {
        if (fileSystem.exists(configPath)) {
            var content = fileSystem.readText(configPath);
            config = Json.parse(content);
        } else {
            config = { plugins: [] };
            saveConfig();
        }
    }
    
    public function loadAll():Void {
        for (pluginConfig in config.plugins) {
            if (!pluginConfig.enabled) continue;
            if (registry.get(pluginConfig.name) != null) continue;

            try {
                var plugin = loadPlugin(pluginConfig);
                if (plugin != null) {
                    plugin.activate(); // ✅ Вызываем БЕЗ аргументов!
                    registry.add(pluginConfig.name, plugin);
                }
            } catch (e:Dynamic) {
                trace('Failed to load plugin: ${pluginConfig.name} - ${e}');
            }
        }
    }

    private function loadPlugin(pluginConfig:PluginConfig):Null<IPlugin> {
        var className = pluginConfig.class;
        var pluginClass = Type.resolveClass(className);
        
        if (pluginClass == null) {
            trace('Plugin class not found: $className');
            return null;
        }

        try {
            // ✅ Передаем ВСЕ зависимости в конструктор плагина
            var args = [viewRegistry, eventBus, pluginConfig.config != null ? pluginConfig.config : {}];
            var plugin = Type.createInstance(pluginClass, args);

            if (!Std.is(plugin, IPlugin)) {
                trace('Plugin $className does not implement IPlugin');
                return null;
            }
            return cast plugin;
        } catch (e:Dynamic) {
            trace('Failed to instantiate plugin $className. Error: ${e}');
            return null;
        }
    }

    public function enable(name:String):Bool {
        for (pluginConfig in config.plugins) {
            if (pluginConfig.name == name && !pluginConfig.enabled) {
                pluginConfig.enabled = true;
                saveConfig();
                
                var plugin = loadPlugin(pluginConfig);
                if (plugin != null) {
                    plugin.activate(); // ✅ Без аргументов
                    registry.add(name, plugin);
                    // ❌ УДАЛЕНО: enabledPlugins.set(name, plugin); (переменной не существует)
                    return true;
                }
                return false;
            }
        }
        return false;
    }

    public function disable(name:String):Bool {
        for (pluginConfig in config.plugins) {
            if (pluginConfig.name == name && pluginConfig.enabled) {
                pluginConfig.enabled = false;
                saveConfig();

                var plugin = registry.get(name);
                if (plugin != null) {
                    plugin.deactivate();
                    registry.remove(name);
                }
                return true;
            }
        }
        return false;
    }

    private function saveConfig():Void {
        var jsonStr = Json.stringify(config, "  ");
        fileSystem.writeText(configPath, jsonStr);
    }
    
    public function getActivePluginNames():Array<String> {
        return registry.getNames(); // ✅ Теперь этот метод существует
    }
}