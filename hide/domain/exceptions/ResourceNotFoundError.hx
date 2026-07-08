package hide.domain.exceptions;

import hide.domain.valueobjects.FilePath;
class ResourceNotFoundError extends haxe.Exception {
    public function new(path:FilePath) {
        super('Resource not found: ${path.toString()}');
    }
}