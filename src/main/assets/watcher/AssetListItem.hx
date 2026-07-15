package src.main.assets.watcher;

typedef AssetListItem = {
    var name:String;
    var path:String;          // Полный путь
    var relativePath:String;  // Путь относительно корня проекта
    var isDirectory:Bool;
    var guid:Null<String>;
    var buildPath:Null<String>;
    var type:String;          // "image", "folder", "unknown"
}