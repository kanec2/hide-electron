package src.main.ipc;

import electron.main.IpcMain;
import electron.IpcMainEvent;
import src.main.services.ServiceLocator;
import hide.shared.types.IpcResponse;

class AssetHandlers {

    public static function setup():Void {
        IpcMain.handle("asset:getList", onGetList);
        IpcMain.handle("asset:init", onInit);
        IpcMain.handle("asset:getMeta", onGetMeta);
        IpcMain.handle("asset:import", onImport);
        // ✅ НОВОЕ: Обработчик для получения base64 превью
        IpcMain.handle("asset:getPreview", onGetPreview);
    }

    /**
     * Генерирует и возвращает base64 превью для Asset Browser.
     */
    private static function onGetPreview(event:Dynamic, data:Dynamic):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "Pipeline not ready" };
        
        var filePath:String = data.path;
        var size:Int = data.size != null ? data.size : 128;
        
        return untyped __js__("new Promise((resolve) => {
            pipeline.getAssetPreview(filePath, size).then(function(previewBase64) {
                resolve({ success: true, data: previewBase64 });
            }).catch(function(err) {
                resolve({ success: false, error: String(err) });
            });
        })");
    }

    private static function onGetList(event:Dynamic, data:Dynamic):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "AssetPipeline not initialized" };
        try {
            var folder = data.folder != null ? data.folder : null;
            var items = pipeline.getAssetsList(folder);
            return { success: true, data: items };
        } catch (e:Dynamic) {
            return { success: false, error: Std.string(e) };
        }
    }
    
    /**
     * Получает список ассетов с превью для Asset Browser.
     */
    private static function onGetAssetList(event:Dynamic, data:Dynamic):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "AssetPipeline not initialized" };
        
        try {
            var folder = data.folder != null ? data.folder : null;
            var items = pipeline.getAssetsList(folder);
            
            // Генерируем превью для изображений
            var itemsWithPreviews = [];
            for (item in items) {
                var itemWithPreview = {
                    name: item.name,
                    path: item.path,
                    relativePath: item.relativePath,
                    isDirectory: item.isDirectory,
                    guid: item.guid,
                    buildPath: item.buildPath,
                    type: item.type,
                    preview: null // Пока null, будем генерировать по запросу
                };
                itemsWithPreviews.push(itemWithPreview);
            }
            
            return { success: true, data: itemsWithPreviews };
        } catch (e:Dynamic) {
            return { success: false, error: Std.string(e) };
        }
    }

    private static function onInit(event:Dynamic, data:Dynamic):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "AssetPipeline not initialized" };
        try {
            pipeline.setProjectRoot(data.projectRoot);
            trace('✅ [Main] Asset Pipeline initialized for: ${data.projectRoot}');
            trace('   Assets folder: ${data.assetsFolder}');
            trace('   Build folder: ${data.buildFolder}');
            return { 
                success: true, 
                data: {
                    assetsPath: pipeline.getAssetsPath(),
                    supportedExtensions: pipeline.getSupportedExtensions()
                }
            };
        } catch (e:Dynamic) {
            return { success: false, error: Std.string(e) };
        }
    }

    private static function onGetMeta(event:Dynamic, guid:String):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "Pipeline not ready" };
        var meta = pipeline.getMeta(guid);
        return meta != null ? { success: true, data: meta } : { success: false, error: 'Meta not found for GUID: $guid' };
    }

    private static function onImport(event:Dynamic, paths:Array<String>):IpcResponse<Dynamic> {
        var pipeline = ServiceLocator.get().assetPipeline;
        if (pipeline == null) return { success: false, error: "Pipeline not ready" };
        return untyped __js__("new Promise((resolve) => {
            pipeline.importAssets(paths).then(function(results) {
                resolve({ success: true, data: results });
            }).catch(function(err) {
                resolve({ success: false, error: err.message || String(err) });
            });
        })");
    }

    /**
     * Отправляет уведомление фронтенду об изменении ассетов.
     * Вызывается при переименовании/удалении/добавлении файлов.
     */
    public static function notifyAssetsChanged(window:electron.main.BrowserWindow):Void {
        if (window != null) {
            window.webContents.send("asset:changed", {});
            trace("📢 [IPC] Asset change notification sent to renderer");
        }
    }
}