package hide.infrastructure.platform.electron;

import hide.domain.services.ILanguageServer;
import hide.domain.services.ILanguageServer.CompletionItem;
import hide.domain.services.ILanguageServer.HoverInfo;
import hide.domain.services.ILanguageServer.Location;
import hide.domain.services.ILanguageServer.Diagnostic;
import hide.infrastructure.platform.electron.ElectronIpcBridge;
import tink.core.Future;
import hx.injection.Service;

/**
 * Electron-специфичная реализация ILanguageServer.
 * Работает через IPC с Language Server в Main Process.
 */
class ElectronLanguageServerAdapter implements ILanguageServer implements Service {
    private var ipcBridge:ElectronIpcBridge;
    private var diagnosticsCallback:Null<String->Array<Diagnostic>->Void>;
    
    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
        
        // Подписываемся на diagnostics от сервера
        ipcBridge.on("lsp:diagnostics", function(data:Dynamic) {
            if (diagnosticsCallback != null) {
                diagnosticsCallback(data.uri, data.diagnostics);
            }
        });
    }
    
    public function start(rootPath:String):Future<Bool> {
        return ipcBridge.invokeSafe("lsp:start", rootPath)
            .map(function(result:Dynamic) {
                return result != null && result.success == true;
            });
    }
    
    public function stop():Void {
        ipcBridge.invokeSafe("lsp:stop", null);
    }
    
    public function didOpen(uri:String, languageId:String, version:Int, text:String):Void {
        ipcBridge.invokeSync("lsp:didOpen", {
            uri: uri,
            languageId: languageId,
            version: version,
            text: text
        });
    }
    
    public function didChange(uri:String, version:Int, text:String):Void {
        ipcBridge.invokeSync("lsp:didChange", {
            uri: uri,
            version: version,
            contentChanges: [{ text: text }]
        });
    }
    
    public function didClose(uri:String):Void {
        ipcBridge.invokeSync("lsp:didClose", { uri: uri });
    }
    
    public function completion(uri:String, line:Int, character:Int):Future<Array<CompletionItem>> {
        return ipcBridge.invokeSafe("lsp:completion", {
            uri: uri,
            line: line,
            character: character
        }).map(function(result:Dynamic) {
            if (result == null) return [];
            return result.items != null ? result.items : [];
        });
    }
    
    public function hover(uri:String, line:Int, character:Int):Future<Null<HoverInfo>> {
        return ipcBridge.invokeSafe("lsp:hover", {
            uri: uri,
            line: line,
            character: character
        });
    }
    
    public function definition(uri:String, line:Int, character:Int):Future<Null<Location>> {
        return ipcBridge.invokeSafe("lsp:definition", {
            uri: uri,
            line: line,
            character: character
        });
    }
    
    public function onDiagnostics(callback:String->Array<Diagnostic>->Void):Void {
        this.diagnosticsCallback = callback;
    }
}