package hide.infrastructure.platform.electron.nwjs;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hx.injection.Service;
class NwFileSystemAdapter implements IFileSystem implements Service {
    public function new() {}
    public function exists(path:FilePath):Bool {
        // TODO: Реализовать через nw.js API
        return false;
    }

    public function readText(path:FilePath):String {
        // TODO: Реализовать через nw.js API
        return "";
    }

    public function writeText(path:FilePath, content:String):Void {
        // TODO: Реализовать через nw.js API
    }

    public function listFiles(path:FilePath, ?recursive:Bool):Array<FilePath> {
        // TODO: Реализовать через nw.js API
        return [];
    }

    public function getAppDataPath():FilePath {
        // TODO: Реализовать через nw.js API
        return new FilePath("");
    }

    public function readBinary(path:FilePath):haxe.io.Bytes {
        // TODO: Реализовать через nw.js API
        return haxe.io.Bytes.alloc(0);
    }
}