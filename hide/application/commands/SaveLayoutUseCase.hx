// hide/application/commands/SaveLayoutUseCase.hx

package hide.application.commands;

import hide.domain.services.ILayoutEngine;
import hide.shared.types.IEventBus;
import hide.shared.events.LayoutSaved;
import hide.domain.valueobjects.LayoutState;

class SaveLayoutUseCase {
    private var layoutEngine:ILayoutEngine;
    private var eventBus:IEventBus;

    public function new(layoutEngine:ILayoutEngine, eventBus:IEventBus) {
        this.layoutEngine = layoutEngine;
        this.eventBus = eventBus;
    }

    public function execute():Void {
        var state:LayoutState = layoutEngine.save(); // ← получаем состояние
        eventBus.publish(new LayoutSaved({}));
    }
}