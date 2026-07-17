// hide/application/services/AssetBrowserService.hx
package hide.application.services;

import hide.infrastructure.platform.electron.ElectronIpcBridge;
import hide.shared.types.IpcResponse;
import hx.injection.Service;
import tink.core.*;
using tink.CoreApi;

typedef AssetItem = {
    var name:String;
    var path:String;
    var relativePath:String;
    var isDirectory:Bool;
    var guid:Null<String>;
    var buildPath:Null<String>;
    var type:String;
}

class AssetBrowserService implements Service {
    private var ipcBridge:ElectronIpcBridge;
    private var currentFolder:String = "Assets";
    private var cache:Map<String, Array<AssetItem>> = new Map();

    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }

    public function getAssets(folder:String):Future<Array<AssetItem>> {
        // Простая проверка кэша (можно усложнить инвалидацией по времени)
        if (cache.exists(folder)) {
            return Future.sync(cache.get(folder));
        }

        return ipcBridge.invokeSafe("asset:getList", {
            projectRoot: getCurrentProjectRoot(), // Нужно получить из ProjectService или передать аргументом
            folder: folder
        }).map(function(response:IpcResponse<Dynamic>) {
            if (response != null && response.success) {
                var items:Array<AssetItem> = cast response.data;
                cache.set(folder, items);
                return items;
            }
            return [];
        });
    }
    
    // Заглушка, пока не внедрим зависимость от ProjectService
    private function getCurrentProjectRoot():String {
        // В реальном проекте лучше инжектить ProjectService и брать rootPath оттуда
        return "D:\\Dev\\tetris-game-project"; 
    }
    
    public function invalidateCache():Void {
        cache = new Map();
        trace('🗑️ [AssetBrowserService] Cache invalidated');
    }
}