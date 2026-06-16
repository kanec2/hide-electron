package hide.domain.entities;

import hide.domain.valueobjects.FilePath;
import hide.domain.enums.ResourceType;

/**
 * Сущность проекта — чистая бизнес-логика, без зависимостей от UI или платформы.
 */
class Project {
    public final id:String;
    public final name:String;
    public final rootPath:FilePath;
    
    private var resources:Map<String, Resource>;
    private var _isDirty:Bool;
    
    public function new(id:String, name:String, rootPath:FilePath) {
        this.id = id;
        this.name = name;
        this.rootPath = rootPath.isValid() ? rootPath : throw 'Invalid path: $rootPath';
        this.resources = new Map();
        this._isDirty = false;
    }
    
    public function addResource(resource:Resource):Void {
        if (resources.exists(resource.id)) {
            throw 'Resource ${resource.id} already exists';
        }
        resources.set(resource.id, resource);
        _isDirty = true;
    }
    
    public function getResource(id:String):Null<Resource> {
        return resources.get(id);
    }
    
    public function getResourcesByType(type:ResourceType):Array<Resource> {
        return [for (r in resources) if (r.type == type) r];
    }
    public static function fromJson(json:String, filePath:FilePath):Project {
        var data = haxe.Json.parse(json);
        // Валидация обязательных полей
        if (data.name == null || StringTools.trim(data.name) == "") {
            throw "Invalid project file: missing or empty 'name' field";
        }
        var id = data.id != null ? Std.string(data.id) : Std.string(Date.now().getTime());
        // Если в JSON есть rootPath, используем его, иначе берем путь к самому файлу
        var pathStr = data.rootPath != null ? data.rootPath : filePath.toString();
        var finalPath = new FilePath(pathStr);

        return new Project(id, data.name, finalPath);
    }
    public function get_isDirty():Bool return _isDirty;
    public function markSaved():Void _isDirty = false;

}