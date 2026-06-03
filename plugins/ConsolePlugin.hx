// plugins/ConsolePlugin.hx

package plugins;

import hide.application.services.ViewRegistry;
import hide.shared.types.IEventBus;
import hide.application.dto.ViewDto;
import hide.domain.services.ILayoutEngine;

/**
 * Пример плагина, регистрирующего view "Консоль".
 */
class ConsolePlugin {
    public function new(viewRegistry:ViewRegistry, eventBus:IEventBus, config:Dynamic) {
        // 1. Регистрация DTO
        viewRegistry.add({
            name: "console",
            label: "Консоль",
            description: "Консоль вывода логов",
            icon: "fa-terminal",
            defaultState: { logLevel: "info" }
        });

        // 2. Регистрация view-фабрики (если нужен ILayoutEngine)
        // (если `ILayoutEngine` доступен — можно сразу зарегистрировать)
        // Но лучше это сделать через ViewFactory:
        viewRegistry.registerView("console", ConsoleViewFactory);
    }
}

// Вспомогательный класс-фабрика
typedef ConsoleViewFactory = {
    function create(container:js.html.Element, state:Dynamic):plugins.console.ConsoleView;
}