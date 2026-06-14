// hide/application/commands/CloseProjectUseCase.hx

package hide.application.commands;

import hide.domain.services.ILayoutEngine;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectClosing;
import hide.shared.events.ProjectClosed;
import hx.injection.*;
class CloseProjectUseCase implements Service {
    private var layoutEngine:ILayoutEngine;
    private var eventBus:IEventBus;

    public function new(layoutEngine:ILayoutEngine, eventBus:IEventBus) {
        this.layoutEngine = layoutEngine;
        this.eventBus = eventBus;
    }

    public function execute():Void {
        // 1. Публикуем ProjectClosing
        eventBus.publish(ProjectClosing, new ProjectClosing());

        // 2. Сохраняем текущий layout
        layoutEngine.save();

        // 3. Публикуем ProjectClosed
        eventBus.publish(ProjectClosed, new ProjectClosed());
    }
}