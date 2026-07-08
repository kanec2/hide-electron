package hide.infrastructure.config;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import haxe.Json;
class PackageJsonLoader {
    private var fileSystem:IFileSystem;
    public function new(fileSystem:IFileSystem) {
        this.fileSystem = fileSystem;
    }

    public function load(path:FilePath):Dynamic {
        if (!fileSystem.exists(path)) {
            return null;
        }
        var content = fileSystem.readText(path);
        return Json.parse(content);
    }
}