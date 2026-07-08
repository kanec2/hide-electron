package hide.infrastructure.persistence;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
class FileSystemRepository {
    private var fileSystem:IFileSystem;
    public function new(fileSystem:IFileSystem) {
        this.fileSystem = fileSystem;
    }

    public function exists(path:FilePath):Bool {
        return fileSystem.exists(path);
    }
}