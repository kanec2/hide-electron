package hide.application.services;

import hide.domain.entities.Resource;
import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hx.injection.Service;
class ResourceService implements Service {
    private var fileSystem:IFileSystem;
    public function new(fileSystem:IFileSystem) {
        this.fileSystem = fileSystem;
    }

    public function loadResource(path:FilePath):Null<Resource> {
        // TODO: Реализовать загрузку ресурса
        return null;
    }

    public function saveResource(resource:Resource):Void {
        // TODO: Реализовать сохранение ресурса
    }
}