package plugins;

import hide.domain.services.IPlugin;
import hide.application.services.ViewRegistry;
import hide.shared.types.IEventBus;
import plugins.console.ConsoleViewFactory;

/**
 * Пример плагина, регистрирующего view "Консоль".
 */
class ConsolePlugin implements IPlugin {
    private var viewRegistry:ViewRegistry;
    private var eventBus:IEventBus;
    private var config:Dynamic;

    // ✅ Все зависимости приходят СЮДА (через рефлексию в PluginManager)
    public function new(viewRegistry:ViewRegistry, eventBus:IEventBus, config:Dynamic) {
        this.viewRegistry = viewRegistry;
        this.eventBus = eventBus;
        this.config = config;
    }

    // ✅ Сигнатура теперь совпадает с чистым IPlugin
    public function activate():Void {
        var logLevel = config != null && config.defaultLogLevel != null ? config.defaultLogLevel : "info";

        viewRegistry.add({
            name: "console",
            label: "Консоль",
            description: "Консоль вывода логов",
            icon: "fa-terminal",
            defaultState: { logLevel: logLevel }
        });

        viewRegistry.registerViewFactory("console", new ConsoleViewFactory());
        trace("ConsolePlugin activated with log level: " + logLevel);
    }

    public function deactivate():Void {
        // Здесь можно удалить view из registry, если нужно
        trace("ConsolePlugin deactivated");
    }
}