// hide/application/services/PluginManager.hx

package hide.application.services;

import hide.application.dto.ViewDto;
import hide.shared.types.IEventBus;
import hide.shared.events.ViewOpened;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

/**
 * Управляет загрузкой и активацией плагинов.
 */
class PluginManager {
    private var plugins:Array<PluginInstance> = [];
    private var config:PluginsConfig;

    public function new(viewRegistry:ViewRegistry, eventBus:IEventBus, ?configPath:String = "plugins.json") {
        // Загрузка конфига
        if (FileSystem.exists(configPath)) {
            config = Json.parse(File.getContent(configPath));
        } else {
            config = { plugins: [] };
            // Сохранить дефолтный конфиг
            File.saveContent(configPath, Json.stringify(config, "  "));
        }

        // Активация плагинов
        for (pluginConfig in config.plugins) {
            if (!pluginConfig.enabled) continue;

            try {
                var instance = loadPlugin(pluginConfig, viewRegistry, eventBus);
                plugins.push({
                    name: pluginConfig.name,
                    class: pluginConfig.class,
                    instance: instance,
                    config: pluginConfig.config
                });
            } catch (e:Dynamic) {
                trace("Failed to load plugin: ${pluginConfig.name} - ${e}");
            }
        }
    }

    private function loadPlugin(pluginConfig:PluginConfig, viewRegistry:ViewRegistry, eventBus:IEventBus):Dynamic {
        var className = pluginConfig.class;
        var params = [
            viewRegistry,
            eventBus,
            pluginConfig.config
        ];

        return Type.createInstance(className, params);
    }

    public function all():Array<PluginInstance> {
        return plugins.copy();
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

typedef PluginsConfig = {
    var plugins:Array<PluginConfig>;
}

typedef PluginConfig = {
    var name:String;
    var class:String;
    var enabled:Bool;
    var config:Dynamic;
}

typedef PluginInstance = {
    var name:String;
    var class:String;
    var instance:Dynamic;
    var config:Dynamic;
}