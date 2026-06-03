// hide/application/commands/OpenViewUseCase.hx

package hide.application.commands;

import hide.domain.services.ILayoutEngine;
import hide.domain.valueobjects.DisplayPosition;

class OpenViewUseCase {
    private var layoutEngine:ILayoutEngine;

    public function new(layoutEngine:ILayoutEngine) {
        this.layoutEngine = layoutEngine;
    }

    public function execute(viewName:String, state:Dynamic, ?position:DisplayPosition):Void {
        layoutEngine.open(viewName, state, position);
    }
}