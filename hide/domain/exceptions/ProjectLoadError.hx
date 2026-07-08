package hide.domain.exceptions;

import hide.domain.valueobjects.FilePath;
class ProjectLoadError extends haxe.Exception {
    public function new(path:FilePath, reason:String) {
        super('Failed to load project at ${path.toString()}: $reason');
    }
}