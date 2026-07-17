package src.main.ipc;

import electron.main.IpcMain;
import electron.IpcMainEvent;
import js.node.Fs;
import js.node.Path;
import electron.main.IpcMain;
import electron.IpcMainEvent;
import src.main.services.ServiceLocator;
import hide.shared.types.IpcResponse;
using StringTools;

class FileSystemHandlers {
    public static function setup():Void {
        IpcMain.on("fs:rename", onRename);
        IpcMain.on("fs:delete", onDelete);
        IpcMain.on("fs:createDirectory", onCreateDirectory);
        IpcMain.on("fs:move", onMove);
        IpcMain.on("fs:exists", onExists);
        IpcMain.on("fs:readText", onReadText);
        IpcMain.on("fs:readBinary", onReadBinary);
        IpcMain.on("fs:writeText", onWriteText);
        IpcMain.on("fs:listFiles", onListFiles);

        IpcMain.handle("project:readDir", onProjectReadDir);
    }
    // ✅ НОВЫЙ МЕТОД: Безопасное чтение директории проекта
    private static function onProjectReadDir(event:Dynamic, data:Dynamic):IpcResponse<Dynamic> {
        var fs = js.node.Fs;
        var pathLib = js.node.Path;
        
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "No project loaded" };
        
        var root = pipeline.getProjectRoot();
        var targetDir = data.path != null ? data.path : root;
        
        // Защита: нельзя выйти за пределы корня проекта
        if (!targetDir.startsWith(root)) {
            return { success: false, error: "Access denied: path outside project root" };
        }

        try {
            if (!fs.existsSync(targetDir)) {
                return { success: true, data: [] };
            }

            var entries = fs.readdirSync(targetDir);
            var result = [];
            
            for (entry in entries) {
                // Игнорируем скрытые файлы и системные папки
                if (entry.startsWith(".") || entry == "node_modules") continue;
                
                var fullPath = pathLib.join(targetDir, entry);
                var stat = fs.statSync(fullPath);
                var relPath = pathLib.relative(root, fullPath).split("\\").join("/");
                
                result.push({
                    name: entry,
                    path: fullPath,
                    relativePath: relPath,
                    isDirectory: stat.isDirectory(),
                    extension: stat.isFile() ? entry.split('.').pop().toLowerCase() : null
                });
            }
            
            // Сортировка: сначала папки, потом файлы, по алфавиту
            result.sort(function(a, b) {
                if (a.isDirectory && !b.isDirectory) return -1;
                if (!a.isDirectory && b.isDirectory) return 1;
                return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
            });
            
            return { success: true, data: result };
        } catch (e:Dynamic) {
            return { success: false, error: Std.string(e) };
        }
    }
    private static function onRename(event:IpcMainEvent, data:Dynamic):Void {
        try {
            var oldPath:String = data.oldPath;
            var newPath:String = data.newPath;
            var oldMetaPath = oldPath + '.meta';
            var newMetaPath = newPath + '.meta';
            
            Fs.renameSync(oldPath, newPath);
            
            if (Fs.existsSync(oldMetaPath)) {
                try {
                    var metaContent = Fs.readFileSync(oldMetaPath, { encoding: "utf-8" });
                    var meta:Dynamic = haxe.Json.parse(metaContent);
                    var oldBuildPath:String = meta.buildPath;
                    
                    Fs.renameSync(oldMetaPath, newMetaPath);
                    
                    if (oldBuildPath != null && Fs.existsSync(oldBuildPath)) {
                        var oldExt = Path.extname(oldBuildPath);
                        var newBaseName = Path.basename(newPath, Path.extname(newPath));
                        var newBuildPath = Path.join(Path.dirname(oldBuildPath), newBaseName + oldExt);
                        
                        if (oldBuildPath != newBuildPath) {
                            try {
                                Fs.renameSync(oldBuildPath, newBuildPath);
                            } catch (e:Dynamic) {
                                trace('⚠️ [FS] Build file rename skipped (locked?): $oldBuildPath');
                            }
                        }
                        meta.buildPath = newBuildPath.split("\\").join("/");
                        Fs.writeFileSync(newMetaPath, haxe.Json.stringify(meta, null, "  "), { encoding: "utf-8" });
                    }
                } catch (e:Dynamic) {
                    trace('⚠️ [FS] Warning during meta/build rename: ${Std.string(e)}');
                }
            }
            // ✅ НОВОЕ: Уведомляем AssetPipeline о переименовании
            var pipeline = ServiceLocator.get().assetPipeline;
            if (pipeline != null) {
                pipeline.onFileRenamed(oldPath, newPath);
            }
            event.returnValue = {};
        } catch (e:Dynamic) {
            var errCode = untyped e.code;
            event.returnValue = { error: (errCode == "EBUSY" || errCode == "EPERM") ? "File is in use." : Std.string(e) };
        }
    }

    private static function onDelete(event:IpcMainEvent, path:String):Void {
        try {
            untyped Fs.rmSync(path, { recursive: true, force: true });
            event.returnValue = {};
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onCreateDirectory(event:IpcMainEvent, path:String):Void {
        try {
            ensureDirectoryExists(path);
            event.returnValue = {};
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onMove(event:IpcMainEvent, data:Dynamic):Void {
        try {
            Fs.renameSync(data.sourcePath, data.destPath);
            event.returnValue = {};
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onExists(event:IpcMainEvent, filePath:String):Void {
        event.returnValue = Fs.existsSync(filePath);
    }

    private static function onReadText(event:IpcMainEvent, filePath:String):Void {
        try {
            if (!Fs.existsSync(filePath)) {
                event.returnValue = { error: "File not found" };
            } else {
                event.returnValue = { content: Fs.readFileSync(filePath, { encoding: "utf-8" }) };
            }
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onReadBinary(event:IpcMainEvent, filePath:String):Void {
        try {
            if (!Fs.existsSync(filePath)) {
                event.returnValue = { error: "File not found" };
            } else {
                event.returnValue = { data: Fs.readFileSync(filePath).toString("base64") };
            }
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onWriteText(event:IpcMainEvent, data:Dynamic):Void {
        try {
            var dir = Path.dirname(data.path);
            if (!Fs.existsSync(dir)) ensureDirectoryExists(dir);
            Fs.writeFileSync(data.path, data.content, { encoding: "utf-8" });
            event.returnValue = {};
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function onListFiles(event:IpcMainEvent, data:Dynamic):Void {
        try {
            var files:Array<String> = [];
            function scan(dir:String) {
                var entries = Fs.readdirSync(dir);
                for (entry in entries) {
                    var fullPath = Path.join(dir, entry);
                    var stat = Fs.statSync(fullPath);
                    if (stat.isDirectory() && data.recursive) {
                        scan(fullPath);
                    } else if (stat.isFile()) {
                        files.push(fullPath);
                    }
                }
            }
            if (Fs.existsSync(data.path)) scan(data.path);
            event.returnValue = { files: files };
        } catch (e:Dynamic) {
            event.returnValue = { error: Std.string(e) };
        }
    }

    private static function ensureDirectoryExists(dir:String):Void {
        if (dir == null || dir == "" || Fs.existsSync(dir)) return;
        ensureDirectoryExists(Path.dirname(dir));
        Fs.mkdirSync(dir);
    }
}