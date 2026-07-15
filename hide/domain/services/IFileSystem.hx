package hide.domain.services;

import hide.domain.valueobjects.FilePath;
import hx.injection.Service;

interface IFileSystem extends Service {
    function exists(path:FilePath):Bool;
    function readText(path:FilePath):String;
    function writeText(path:FilePath, content:String):Void;
    function listFiles(path:FilePath, ?recursive:Bool):Array<FilePath>;
    function getAppDataPath():FilePath;
    
    // ✅ НОВОЕ: для бинарных файлов (текстуры, меши)
    function readBinary(path:FilePath):haxe.io.Bytes;

    // ✅ ДОБАВЛЯЕМ методы для Project Tree:
    function rename(oldPath: FilePath, newPath: FilePath): Void;
    function delete(path: FilePath): Void;
    function createDirectory(path: FilePath): Void;
    function move(sourcePath: FilePath, destPath: FilePath): Void;
}