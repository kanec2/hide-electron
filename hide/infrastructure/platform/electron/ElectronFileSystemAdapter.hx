package hide.infrastructure.platform.electron;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.domain.exceptions.FileNotFoundError;
import js.Node;

/**
 * Адаптер файловой системы для Electron.
 * Реализует интерфейс IFileSystem из domain layer.
 */
class ElectronFileSystemAdapter implements IFileSystem {
    private var fs:Dynamic;
    private var path:Dynamic;
    private var app:Dynamic;
    
    public function new() {
        var electron = js.Node.require("electron");
        fs = js.Node.require("fs");
        path = js.Node.require("path");
        app = electron.app;
    }
    
    public function exists(filePath:FilePath):Bool {
        return fs.existsSync(filePath.toString());
    }

    public function readText(filePath:FilePath):String {
        if (!exists(filePath)) {
            throw new FileNotFoundError(filePath);
        }
        try {
            return fs.readFileSync(filePath, "utf-8");
        } catch (e:Dynamic) {
            throw new FileNotFoundError(filePath); // Или IOError, если есть такой класс
        }
    }
    
    public function writeText(filePath:FilePath, content:String):Void {
        try {
            var dir = path.dirname(filePath);
            // Автоматически создаём все необходимые родительские директории
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
            fs.writeFileSync(filePath, content, "utf-8");
        } catch (e:Dynamic) {
            throw 'Failed to write file: $filePath. Error: $e';
        }
    }
    
    public function listFiles(filePath:FilePath, ?recursive:Bool = false):Array<FilePath> {
        var result:Array<FilePath> = [];
        
        function scan(dir:String) {
            var entries = fs.readdirSync(dir);
            for (entry in entries) {
                var fullPath = path.join(dir, entry);
                var stat = fs.statSync(fullPath);
                
                if (stat.isDirectory() && recursive) {
                    scan(fullPath);
                } else if (stat.isFile()) {
                    result.push(new FilePath(fullPath));
                }
            }
        }

        if (exists(filePath)) {
            scan(filePath);
        }
        return result;
    }
    
    public function getAppDataPath():FilePath {
        // В Electron это возвращает путь к папке пользовательских данных (например, AppData/Roaming/YourApp)
        return new FilePath(app.getPath("userData"));
    }
}