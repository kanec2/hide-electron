package hide.infrastructure.platform.electron;

import hx.injection.Service;
import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.domain.exceptions.FileNotFoundError;

class ElectronFileSystemAdapter implements IFileSystem implements Service {
    private var ipcBridge:ElectronIpcBridge;
    
    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }

    public function exists(filePath:FilePath):Bool {
        return ipcBridge.invokeSync("fs:exists", filePath.toString());
    }

    public function readText(filePath:FilePath):String {
        if (!exists(filePath)) {
            throw new FileNotFoundError(filePath);
        }
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

    public function listFiles(filePath: FilePath, ?recursive: Bool = false): Array<FilePath> {
        var result: Dynamic = ipcBridge.invokeSync("fs:listFiles", {
            path: filePath.toString(),
            recursive: recursive
        });
        if (result.error != null) return [];
        
        // Явное приведение типа, чтобы компилятор знал, что это массив
        var files: Array<String> = cast result.files;
        return [for (path in files) new FilePath(path)];
    }

    public function getAppDataPath():FilePath {
        var path = ipcBridge.invokeSync("app:getAppDataPath");
        return new FilePath(path);
    }
    
    // ✅ НОВОЕ: чтение бинарных файлов
    public function readBinary(filePath:FilePath):haxe.io.Bytes {
        if (!exists(filePath)) {
            throw new FileNotFoundError(filePath);
        }
        
        var result = ipcBridge.invokeSync("fs:readBinary", filePath.toString());
        
        if (result.error != null) {
            throw new FileNotFoundError(filePath);
        }
        
        // Декодируем Base64 обратно в Bytes
        var base64:String = result.data;
        return haxe.crypto.Base64.decode(base64);
    }
}