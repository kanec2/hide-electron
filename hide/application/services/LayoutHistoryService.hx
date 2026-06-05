package hide.application.services;

// hide/application/services/LayoutHistoryService.hx
class LayoutHistoryService {
    private var history:Array<{name:String, state:Dynamic}> = [];
    private var layoutEngine:ILayoutEngine;

    public function new(layoutEngine:ILayoutEngine) { ... }

    public function pushToHistory(name:String, state:Dynamic):Void {
        history.push({name: name, state: state});
        if (history.length > 20) history.shift(); // Лимит истории
    }

    public function reopenLast():Void {
        var last = history.pop();
        if (last != null) {
            // Используем стандартный open, но без сохранения в историю, чтобы не было цикла
            layoutEngine.open(last.name, last.state, Center); 
        }
    }
}