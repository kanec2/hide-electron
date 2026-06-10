package hide.infrastructure.platform.electron;

import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.domain.exceptions.FileNotFoundError;

class ElectronFileSystemAdapter implements IFileSystem {
    private var ipcBridge:ElectronIpcBridge;
    
    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }
    
    public function exists(filePath:FilePath):Bool {
        // Синхронный вызов через IPC
        return ipcBridge.invokeSync("fs:exists", filePath.toString());
    }
    
    public function readText(filePath:FilePath):String {
        if (!exists(filePath)) {
            throw new FileNotFoundError(filePath);
        }
        
        // Синхронный вызов для простоты (можно заменить на асинхронный)
        var result = ipcBridge.invokeSync("fs:readText", filePath.toString());
        
        if (result.error != null) {
            throw new FileNotFoundError(filePath);
        }
        
        return result.content;
    }
    
    public function writeText(filePath:FilePath, content:String):Void {
        var result = ipcBridge.invokeSync("fs:writeText", {
            path: filePath.toString(),
            content: content
        });
        
        if (result.error != null) {
            throw 'Failed to write file: ${filePath.toString()}';
        }
    }
    
    public function listFiles(filePath:FilePath, ?recursive:Bool = false):Array<FilePath> {
        var result = ipcBridge.invokeSync("fs:listFiles", {
            path: filePath.toString(),
            recursive: recursive
        });
        
        if (result.error != null) {
            return [];
        }
        
        return [for (path in result.files) new FilePath(path)];
    }
    
    public function getAppDataPath():FilePath {
        var path = ipcBridge.invokeSync("app:getAppDataPath");
        return new FilePath(path);
    }
}