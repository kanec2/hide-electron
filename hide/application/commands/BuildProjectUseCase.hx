package hide.application.commands;

import hide.shared.types.IEventBus;
import hx.injection.Service;
class BuildProjectUseCase implements Service {
    private var eventBus:IEventBus;
    public function new(eventBus:IEventBus) {
        this.eventBus = eventBus;
    }

    public function execute():Void {
        // TODO: Реализовать сборку проекта
        trace("BuildProjectUseCase: Not implemented yet");
    }
}