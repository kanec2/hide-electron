// plugins/console/ConsoleView.hx

package plugins.console;

import hide.domain.services.IElement;

class ConsoleView {
    private var container:IElement;
    private var logLevel:String;

    public function new(container:IElement, state:Dynamic) {
        this.container = container;
        this.logLevel = state.logLevel != null ? state.logLevel : "info";

        container.setInnerHtml("<div class='console'><div class='console-content'></div></div>");
    }

    public function log(level:String, message:String):Void {
        if (shouldLog(level)) {
            // Здесь можно добавить UI-логику
            trace("[$level] $message");
        }
    }

    private function shouldLog(level:String):Bool {
        var levels = ["error", "warn", "info", "debug"];
        var indexLevel = levels.indexOf(level);
        var indexConfig = levels.indexOf(logLevel);
        return indexLevel >= indexConfig;
    }
}