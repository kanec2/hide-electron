package hide.application.commands;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.shared.types.IEventBus;
import hide.shared.events.ResourceOpened;
import hx.injection.Service;
class OpenResourceUseCase implements Service {
    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;
    public function new(fileSystem:IFileSystem, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.eventBus = eventBus;
    }

    public function execute(path:FilePath):Void {
        if (!fileSystem.exists(path)) {
            trace("Resource not found: " + path.toString());
            return;
        }
        
        // TODO: Определить тип ресурса и открыть соответствующий редактор
        eventBus.publish(ResourceOpened, new ResourceOpened());
    }
}