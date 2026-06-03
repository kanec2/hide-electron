// hide/application/commands/CloseProjectUseCase.hx

package hide.application.commands;

import hide.domain.services.ILayoutEngine;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectClosing;
import hide.shared.events.ProjectClosed;

class CloseProjectUseCase {
    private var layoutEngine:ILayoutEngine;
    private var eventBus:IEventBus;

    public function new(layoutEngine:ILayoutEngine, eventBus:IEventBus) {
        this.layoutEngine = layoutEngine;
        this.eventBus = eventBus;
    }

    public function execute():Void {
        // 1. Публикуем ProjectClosing
        eventBus.publish(new ProjectClosing());

        // 2. Сохраняем текущий layout
        layoutEngine.save();

        // 3. Публикуем ProjectClosed
        eventBus.publish(new ProjectClosed());
    }
}