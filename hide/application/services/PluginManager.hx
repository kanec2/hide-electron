// hide/application/services/PluginManager.hx

package hide.application.services;

import hide.shared.types.IEventBus;
import hide.domain.services.IPlugin;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

/**
 * Управляет загрузкой и активацией плагинов.
 * Плагины загружаются из plugins.json, но инициализируются через PluginRegistry.
 */
class PluginManager {
    private var registry:PluginRegistry;
    private var config:PluginsConfig;
    private var enabledPlugins:Map<String, IPlugin> = [];

    public function new(registry:PluginRegistry, ?configPath:String = "plugins.json") {
        this.registry = registry;

        // Загрузка конфига
        if (FileSystem.exists(configPath)) {
            config = Json.parse(File.getContent(configPath));
        } else {
            config = { plugins: [] };
            File.saveContent(configPath, Json.stringify(config, "  "));
        }
    }

    /**
     * Загружает и активирует плагины из конфига.
     */
    public function loadAll():Void {
        for (pluginConfig in config.plugins) {
            if (!pluginConfig.enabled) continue;

            try {
                var plugin = loadPlugin(pluginConfig);
                if (plugin != null) {
                    plugin.activate(pluginRegistry, eventBus);
                    enabledPlugins.set(pluginConfig.name, plugin);
                }
            } catch (e:Dynamic) {
                trace("Failed to load plugin: ${pluginConfig.name} - ${e}");
            }
        }
    }

    // hide/application/services/PluginManager.hx

    private function loadPlugin(pluginConfig:PluginConfig):Null<IPlugin> {
        var className = pluginConfig.class;
        var plugin = PluginFactory.load(className);

        if (plugin == null) {
            trace("Plugin not found or invalid: $className");
            return null;
        }

        return plugin;
    }

    public function enable(name:String):Bool {
        for (plugin in config.plugins) {
            if (plugin.name == name && !plugin.enabled) {
                plugin.enabled = true;
                saveConfig();
                return true;
            }
        }
        return false;
    }

    public function disable(name:String):Bool {
        for (plugin in config.plugins) {
            if (plugin.name == name && plugin.enabled) {
                plugin.enabled = false;
                saveConfig();
                return true;
            }
        }
        return false;
    }

    private function saveConfig():Void {
        File.saveContent("plugins.json", Json.stringify(config, "  "));
    }
}