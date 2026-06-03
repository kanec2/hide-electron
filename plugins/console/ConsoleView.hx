package plugins.console;

// plugins/console/ConsoleView.hx

import hide.presentation.ui.View;
import js.html.Element;

class ConsoleView extends View<Dynamic> {
    private var logContainer:Element;
    private var logLevel:String = "info";

    public function new(container:Element, state:Dynamic) {
        super(container, state);

        // Инициализация UI
        logContainer = container.createChild("div", "console-log");
        logContainer.innerHtml = "<div class='console-title'>Консоль</div>";

        // Настройка уровня логов
        if (state != null && state.logLevel != null) {
            logLevel = state.logLevel;
        }

        // Добавить кнопку очистки
        var clearBtn = container.createChild("button", "console-clear");
        clearBtn.innerHtml = "Очистить";
        clearBtn.addEventListener("click", function(_) {
            logContainer.innerHtml = "";
        });
    }

    public function log(level:String, message:String):Void {
        if (shouldLog(level)) {
            var entry = logContainer.createChild("div", "log-entry ${level}");
            entry.innerHtml = "<span class='timestamp'>${getTimestamp()}</span> ${message}";
        }
    }

    private function shouldLog(level:String):Bool {
        var levels = ["error", "warn", "info", "debug"];
        var indexLevel = levels.indexOf(level);
        var indexConfig = levels.indexOf(logLevel);
        return indexLevel >= indexConfig;
    }

    private function getTimestamp():String {
        var date = new Date();
        return '${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}';
    }
}