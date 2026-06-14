package hide.domain.services;

import hide.domain.valueobjects.FilePath;
import hx.injection.Service;

interface IFileSystem extends Service {
    function exists(path:FilePath):Bool;
    function readText(path:FilePath):String;
    function writeText(path:FilePath, content:String):Void;
    function listFiles(path:FilePath, ?recursive:Bool):Array<FilePath>;
    function getAppDataPath():FilePath;
}