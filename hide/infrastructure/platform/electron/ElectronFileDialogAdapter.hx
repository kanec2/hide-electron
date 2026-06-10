package hide.infrastructure.platform.electron;

import hide.domain.services.IFileDialog;
import tink.core.Future;

class ElectronFileDialogAdapter implements IFileDialog {
    private var ipcBridge:ElectronIpcBridge;
    
    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }
    
    public function showOpen(?options: { ?filters: Array<FileFilter> }):Future<Null<String>> {
        var electronOptions = {
            properties: ["openFile"],
            filters: options != null && options.filters != null ? options.filters : []
        };
        
        return ipcBridge.invokeSafe("dialog:showOpen", electronOptions)
            .map(function(result:Dynamic) {
                if (result == null || result.canceled || result.filePaths.length == 0) {
                    return null;
                }
                return result.filePaths[0];
            });
    }
    
    public function showSave(?options: { ?filters: Array<FileFilter>, ?defaultPath: String }):Future<Null<String>> {
        var electronOptions = {
            properties: ["createDirectory", "showOverwriteConfirmation"],
            filters: options != null && options.filters != null ? options.filters : [],
            defaultPath: options != null ? options.defaultPath : null
        };
        
        return ipcBridge.invokeSafe("dialog:showSave", electronOptions)
            .map(function(result:Dynamic) {
                if (result == null || result.canceled) {
                    return null;
                }
                return result.filePath;
            });
    }
    
    public function showDirectory():Future<Null<String>> {
        return ipcBridge.invokeSafe("dialog:showDirectory", {
            properties: ["openDirectory", "createDirectory"]
        }).map(function(result:Dynamic) {
            if (result == null || result.canceled) {
                return null;
            }
            return result.filePaths[0];
        });
    }
}