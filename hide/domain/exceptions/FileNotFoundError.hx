package hide.domain.exceptions;

import hide.domain.valueobjects.FilePath;

class FileNotFoundError extends haxe.Exception {
    public function new(path:FilePath) {
        super('File not found: ${path.toString()}');
    }
}