package hide.application.commands;

import hide.shared.types.IEventBus;
import hx.injection.Service;
class ExportDatabaseUseCase implements Service {
    private var eventBus:IEventBus;
    public function new(eventBus:IEventBus) {
        this.eventBus = eventBus;
    }

    public function execute():Void {
        // TODO: Реализовать экспорт базы данных
        trace("ExportDatabaseUseCase: Not implemented yet");
    }
}