package hide.domain.entities;

import hide.domain.valueobjects.FilePath;
import haxe.io.Path; // <-- Добавь этот импорт

/**
 * Сущность проекта — чистая бизнес-логика.
 */
class Project {
    public final id:String;
    public var name:String;
    public final rootPath:FilePath;
    
    // Конфигурация путей
    public var assetsPath:String = "Assets";
    public var sourcePath:String = "Source";
    public var buildPath:String = "Build";
    
    // Настройки редактора
    public var lastLayout:String = "Default";
    public var recentScenes:Array<String> = [];
    
    // Настройки движка
    public var defaultRenderer:String = "PBR";
    public var startupScene:Null<String> = null;

    private var _isDirty:Bool;

    public function new(id:String, name:String, rootPath:FilePath) {
        this.id = id;
        this.name = name;
        this.rootPath = rootPath.isValid() ? rootPath : throw 'Invalid path: $rootPath';
        this._isDirty = false;
    }

    /**
     * Получает полный путь к папке ассетов.
     */
    public function getFullAssetsPath():FilePath {
        return new FilePath(rootPath.toString() + "/" + assetsPath);
    }

    /**
     * Получает полный путь к папке исходников.
     */
    public function getFullSourcePath():FilePath {
        return new FilePath(rootPath.toString() + "/" + sourcePath);
    }

    /**
     * Получает полный путь к папке сборки.
     */
    public function getFullBuildPath():FilePath {
        return new FilePath(rootPath.toString() + "/" + buildPath);
    }

    public static function fromJson(json:String, filePath:FilePath):Project {
        var data = haxe.Json.parse(json);
        
        if (data.name == null || StringTools.trim(data.name) == "") {
            throw "Invalid project file: missing or empty 'name' field";
        }
        
        // ✅ ИСПРАВЛЕНИЕ: Используем haxe.io.Path для получения родительской директории
        var pathObj = new Path(filePath.toString());
        var parentDir = pathObj.dir != null && pathObj.dir != "" ? pathObj.dir : ".";
        var rootPath = new FilePath(parentDir);

        var project = new Project(
            data.id != null ? Std.string(data.id) : Std.string(Date.now().getTime()),
            data.name,
            rootPath
        );

        // Восстанавливаем пути, если они есть в файле
        if (data.paths != null) {
            if (data.paths.assets != null) project.assetsPath = data.paths.assets;
            if (data.paths.source != null) project.sourcePath = data.paths.source;
            if (data.paths.build != null) project.buildPath = data.paths.build;
        }

        // Восстанавливаем настройки редактора
        if (data.editor != null) {
            if (data.editor.lastLayout != null) project.lastLayout = data.editor.lastLayout;
            if (data.editor.recentScenes != null) project.recentScenes = data.editor.recentScenes;
            if (data.editor.startupScene != null) project.startupScene = data.editor.startupScene;
        }

        // Восстанавливаем настройки движка
        if (data.engine != null) {
            if (data.engine.defaultRenderer != null) project.defaultRenderer = data.engine.defaultRenderer;
        }

        return project;
    }

    public function toJson():String {
        return haxe.Json.stringify({
            version: "1.0.0",
            name: name,
            paths: {
                assets: assetsPath,
                source: sourcePath,
                build: buildPath
            },
            editor: {
                lastLayout: lastLayout,
                recentScenes: recentScenes,
                startupScene: startupScene
            },
            engine: {
                defaultRenderer: defaultRenderer
            }
        }, null, "  ");
    }

    public function get_isDirty():Bool return _isDirty;
    public function markSaved():Void _isDirty = false;
    public function markDirty():Void _isDirty = true;
}