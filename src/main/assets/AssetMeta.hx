package src.main.assets;

/**
 * Структура .meta файла ассета.
 * Хранится рядом с исходным файлом в папке Assets/.
 */
typedef AssetMeta = {
    var guid:String;
    var type:String; // "texture", "audio", "font", "model", "shader"
    var sourcePath:String;
    var buildPath:String;
    var settings:Dynamic;
    var lastModified:Int;
    var version:Int;
}

