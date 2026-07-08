package hide.infrastructure.config;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.domain.entities.UserSettings;
import haxe.Json;
class UserSettingsLoader {
    private var fileSystem:IFileSystem;
    public function new(fileSystem:IFileSystem) {
        this.fileSystem = fileSystem;
    }

    public function load(path:FilePath):UserSettings {
        if (!fileSystem.exists(path)) {
            return new UserSettings();
        }
        var content = fileSystem.readText(path);
        var data = Json.parse(content);
        
        var settings = new UserSettings();
        if (Reflect.hasField(data, "theme")) settings.theme = data.theme;
        if (Reflect.hasField(data, "fontSize")) settings.fontSize = data.fontSize;
        if (Reflect.hasField(data, "autoSave")) settings.autoSave = data.autoSave;
        
        return settings;
    }

    public function save(path:FilePath, settings:UserSettings):Void {
        var data = {
            theme: settings.theme,
            fontSize: settings.fontSize,
            autoSave: settings.autoSave
        };
        fileSystem.writeText(path, Json.stringify(data, null, "  "));
    }
}