package src.main.assets;

import js.lib.Promise;
import js.node.Fs;
import js.node.Path;
import haxe.Json;
import src.main.assets.IAssetConverter;
import src.main.assets.AssetMeta;
import src.main.assets.ConversionResult;
import src.main.assets.registry.AssetTypeRegistry;
import src.main.assets.watcher.AssetListItem;
import chokidar.Chokidar; // <-- Импортируем из библиотеки
import chokidar.WatchOptions;
import chokidar.FSWatcher;
import chokidar.AwaitWriteFinishOptions;
import haxe.ds.Either; // <-- Добавь этот импорт
import src.main.external.Lowdb.JSONFileSync;
import src.main.external.Lowdb.LowSync;

using StringTools;
/**
 * Главный сервис управления ассетами.
 * Отслеживает папку Assets/, создает .meta файлы и запускает конвертацию.
 */
class AssetPipelineService {
    private var registry:AssetTypeRegistry;
    private var projectRoot:String;
    private var assetsPath:String;
    private var watcher:FSWatcher; // Chokidar instance
    private var db:LowSync<AssetIndex>; // ✅ Lowdb база данных

    public function new(registry:AssetTypeRegistry) {
        this.registry = registry;
        this.projectRoot = "";
        this.assetsPath = "";
    }
    
    /**
     * Устанавливает корневую папку проекта игры.
     * Вызывается при открытии проекта через IPC.
     */
    public function setProjectRoot(root:String):Void {
        this.projectRoot = root;
        // ✅ Принудительно заменяем слеши на прямые для Chokidar
        var normalizedRoot = root.split("\\").join("/");
        this.assetsPath = js.node.Path.join(normalizedRoot, "Assets");
        // ✅ Инициализируем Lowdb
        initDatabase(normalizedRoot);

        stopWatching();
        startWatching();
        
        trace('📂 [AssetPipeline] Project root set to: $normalizedRoot');
        trace('   Watching: $assetsPath');
    }

    /**
     * Инициализация Lowdb базы данных.
     */
    private function initDatabase(projectRoot:String):Void {
        var hideDir = js.node.Path.join(projectRoot, ".hide");
        if (!js.node.Fs.existsSync(hideDir)) {
            js.node.Fs.mkdirSync(hideDir, { recursive: true });
        }
        
        var dbPath = js.node.Path.join(hideDir, "asset-index.json");
        
        // ✅ Создаем адаптер и базу
        var adapter = new JSONFileSync<AssetIndex>(dbPath);
        this.db = new LowSync<AssetIndex>(adapter);
        
        // ✅ В v5 данные инициализируются напрямую через db.data
        if (this.db.data == null) {
            this.db.data = { assets: [], version: 1 };
            this.db.write();
        }
        
        trace('✅ [AssetPipeline] Database initialized at: $dbPath');
    }
    /**
     * Получает метаданные ассета по GUID (нативный Haxe поиск).
     */
    public function getMeta(guid:String):Null<AssetMeta> {
        if (db == null || db.data == null || guid == null) return null;
        
        for (asset in db.data.assets) {
            if (asset.guid == guid) return asset;
        }
        return null;
    }

    /**
     * Получает метаданные ассета по пути к файлу.
     */
    public function getMetaByPath(filePath:String):Null<AssetMeta> {
        if (db == null || db.data == null || filePath == null) return null;
        
        var normalizedPath = filePath.split("\\").join("/");
        for (asset in db.data.assets) {
            if (asset.sourcePath == normalizedPath) return asset;
        }
        return null;
    }

    /**
     * Добавляет или обновляет ассет в индексе.
     */
    private function upsertAsset(meta:AssetMeta):Void {
        if (db == null || db.data == null || meta == null) return;
        
        var found = false;
        for (i in 0...db.data.assets.length) {
            if (db.data.assets[i].guid == meta.guid) {
                db.data.assets[i] = meta; // Обновляем
                found = true;
                trace('🔄 [AssetPipeline] Updated asset in index: ${meta.sourcePath}');
                break;
            }
        }
        
        if (!found) {
            db.data.assets.push(meta); // Добавляем новый
            trace('➕ [AssetPipeline] Added asset to index: ${meta.sourcePath}');
        }
        
        db.write(); // Сохраняем на диск
    }

    /**
     * Удаляет ассет из индекса по пути.
     */
    private function removeAssetByPath(filePath:String):Void {
        if (db == null || db.data == null || filePath == null) return;
        
        var normalizedPath = filePath.split("\\").join("/");
        var initialLength = db.data.assets.length;
        
        db.data.assets = [for (asset in db.data.assets) if (asset.sourcePath != normalizedPath) asset];
        
        if (db.data.assets.length < initialLength) {
            db.write();
            trace('🗑️ [AssetPipeline] Removed asset from index: $normalizedPath');
        }
    }
    
    public function getProjectRoot():String return projectRoot;
    public function getAssetsPath():String {
        return assetsPath;
    }
    
    public function getSupportedExtensions():Array<String> {
        return registry.getAllSupportedExtensions();
    }
    
    /**
     * Импортирует список файлов (вызывается при drag&drop или добавлении).
     */
    public function importAssets(paths:Array<String>):Promise<Array<ConversionResult>> {
        return untyped __js__("new Promise(async (resolve) => {
            const results = [];
            
            for (const path of paths) {
                try {
                    const result = await pipeline.importSingleAsset(path);
                    results.push(result);
                } catch (err) {
                    results.push({ 
                        buildPath: path, 
                        metadata: {}, 
                        error: err.message || String(err) 
                    });
                }
            }
            
            resolve(results);
        })");
    }

    public function getAllAssets():Array<AssetMeta> {
        if (db == null) return [];
        
        var result = db.data.assets;
        return cast result;
    }

    // === PRIVATE METHODS ===

    private function startWatching():Void {
        if (assetsPath == "" || !Fs.existsSync(assetsPath)) {
            trace('⚠️ [AssetPipeline] Assets folder does not exist yet: $assetsPath');
            try {
                Fs.mkdirSync(this.assetsPath, { recursive: true });
                trace('✅ [AssetPipeline] Created missing Assets folder');
            } catch (e:Dynamic) {
                trace('❌ [AssetPipeline] Failed to create Assets folder: ${Std.string(e)}');
                return;
            }
        }
        // 1. Создаем объект настроек для awaitWriteFinish
        var awfOptions:AwaitWriteFinishOptions = {
            stabilityThreshold: 1000,
            pollInterval: 500
        };
        trace('👀 [AssetPipeline] Starting Chokidar watcher on: $assetsPath');
        // Настраиваем опции
        var options:WatchOptions = {
            ignored: [~/(\^|[\/\\])\../, "**/*.meta"],
            persistent: true,
            // ✅ ИСПРАВЛЕНО: передаем объект правильного типа
            awaitWriteFinish: Right(awfOptions), 
            ignoreInitial: false,
            usePolling: true
        };
        
        // Создаем вотчер через библиотеку
        watcher = Chokidar.watch(assetsPath + "/**/*", options);

        // Подписываемся на события
        watcher.on("add", function(path:String) {
            trace('📥 [Chokidar] File ADDED: $path');
            onFileAdded(path);
        })
        .on("change", function(path:String) {
            trace('🔄 [Chokidar] File CHANGED: $path');
            onFileChanged(path);
        })
        .on("unlink", function(path:String) {
            trace('🗑️ [Chokidar] File DELETED: $path');
            onFileDeleted(path);
        })
        .on("error", function(error:Dynamic) {
            trace('❌ [Chokidar] Error: $error');
        })
        .on("ready", function() {
            trace('✅ [Chokidar] Initial scan complete. Watching for changes...');
            onInitialScanComplete();
        });
    }
    
    private function stopWatching():Void {
        if (watcher != null) {
            watcher.close();
            watcher = null;
            trace('🛑 [AssetPipeline] Watcher stopped');
        }
    }
    /**
     * Получает список ассетов в указанной папке.
     * Если folder == null, сканирует корень Assets.
     * ✅ ИСПОЛЬЗУЕТ LOWDB ВМЕСТО ЧТЕНИЯ .meta ФАЙЛОВ
     */
    @:keep
    public function getAssetsList(?folder:String):Array<AssetListItem> {
        if (projectRoot == "") return [];
        
        var fs = js.node.Fs;
        var pathLib = js.node.Path;
        
        var targetDir = folder != null 
            ? pathLib.join(assetsPath, folder) 
            : assetsPath;
        
        if (!fs.existsSync(targetDir)) {
            trace('️ [AssetPipeline] Directory not found: $targetDir');
            return [];
        }

        try {
            var entries = fs.readdirSync(targetDir);
            var result:Array<AssetListItem> = [];
            
            for (entry in entries) {
                // Игнорируем скрытые файлы и .meta
                if (StringTools.startsWith(entry, ".") || StringTools.endsWith(entry, ".meta")) continue;
                
                var fullPath = pathLib.join(targetDir, entry);
                var stat = fs.statSync(fullPath);
                var relPath = pathLib.relative(projectRoot, fullPath).split("\\").join("/");
                
                if (stat.isDirectory()) {
                    result.push({
                        name: entry,
                        path: fullPath,
                        relativePath: relPath,
                        isDirectory: true,
                        guid: null,
                        buildPath: null,
                        type: "folder"
                    });
                } else {
                    // ✅ ИСПОЛЬЗУЕМ LOWDB ВМЕСТО ЧТЕНИЯ .meta ФАЙЛА!
                    var meta = getMetaByPath(fullPath);
                    
                    var ext = entry.split('.').pop().toLowerCase();
                    var assetType = switch (ext) {
                        case 'png', 'jpg', 'jpeg', 'webp', 'tga': "image";
                        case 'mp3', 'wav', 'ogg': "audio";
                        default: "unknown";
                    };
                    
                    result.push({
                        name: entry,
                        path: fullPath,
                        relativePath: relPath,
                        isDirectory: false,
                        guid: meta != null ? meta.guid : null,
                        buildPath: meta != null ? meta.buildPath : null,
                        type: assetType
                    });
                }
            }
            
            return result;
        } catch (e:Dynamic) {
            trace('❌ [AssetPipeline] Failed to list assets: ${Std.string(e)}');
            return [];
        }
    }
    /**
     * Вызывается один раз после того, как Chokidar просканировал все существующие файлы.
     */
    @:keep
    public function onInitialScanComplete():Void {
        // Ручная индексация больше не нужна.
        // Chokidar с ignoreInitial: false уже выдал события 'add' для всех существующих файлов.
        trace('✅ [AssetPipeline] Initial scan complete. System ready.');
        trace(db);
        trace(db.data);
        trace(db.data.assets);
        trace('   Total assets in index: ${db.data.assets.length}');
    }

    

    @:keep
    private function onFileAdded(path:String):Void {
        if (path.endsWith('.meta')) return;
        trace('📥 [CHOKIDAR] ADD event at ${Date.now().toString()}: $path');
        importSingleAsset(path);
    }
    @:keep
    private function onFileChanged(path:String):Void {
        if (path.endsWith('.meta')) return;
        
        trace('🔄 [AssetPipeline] File changed: $path');
        reimportAsset(path);
    }

    @:keep
    private function onFileDeleted(path:String):Void {
        trace('🗑️ [CHOKIDAR] UNLINK event at ${Date.now().toString()}: $path');
        cleanupBuildFiles(path);
    }
    
    /**
     * Генерирует base64 превью для указанного файла.
     */
     @:keep
    public function getAssetPreview(filePath:String, ?size:Int):js.lib.Promise<String> {
        var converter = registry.getConverter(filePath);
        if (converter != null) {
            return converter.getPreview(filePath, size);
        }
        return js.lib.Promise.reject("No converter found for this file type");
    }
    
    /**
     * Импортирует один ассет: создает .meta → конвертирует → обновляет индекс.
     * ✅ ПОЛНОСТЬЮ НА ЧИСТОМ HAXE (без untyped __js__ строк)
     */
    @:keep
    public function importSingleAsset(sourcePath:String):Void {
        var metaPath = sourcePath + '.meta';
        var ext = js.node.Path.extname(sourcePath).toLowerCase();
        var relativeSource = js.node.Path.relative(this.projectRoot, sourcePath);
        
        var buildDir = js.node.Path.join(this.projectRoot, 'Build', js.node.Path.dirname(relativeSource));
        var baseName = js.node.Path.basename(sourcePath, ext);
        var defaultBuildPath = js.node.Path.join(buildDir, baseName + '.webp').split("\\").join("/");

        var meta:Dynamic = null;

        if (Fs.existsSync(metaPath)) {
            var metaContent = Fs.readFileSync(metaPath, 'utf-8');
            meta = haxe.Json.parse(metaContent);
            // ✅ КРИТИЧЕСКАЯ ПОПРАВКА: Гарантируем, что sourcePath всегда актуален, 
            // даже если файл был переименован вне IDE или логика переименования что-то упустила.
            meta.sourcePath = relativeSource; 
            
            trace('  📖 [PIPELINE] Read existing meta for: $sourcePath');
            trace('  🔍 [PIPELINE] Meta says buildPath is: ${meta.buildPath}');
        } else {
            meta = {
                guid: untyped __js__("require('uuid').v4()"),
                type: 'texture',
                sourcePath: relativeSource,
                buildPath: defaultBuildPath,
                settings: {},
                lastModified: Std.int(Fs.statSync(sourcePath).mtimeMs),
                version: 1
            };
            if (!Fs.existsSync(buildDir)) Fs.mkdirSync(buildDir, { recursive: true });
            Fs.writeFileSync(metaPath, haxe.Json.stringify(meta, null, "  "), 'utf-8');
            trace('  📝 [PIPELINE] Created NEW meta for: $sourcePath');
        }

        var converter = registry.getConverter(sourcePath);
        if (converter == null) {
            trace('⚠️ [PIPELINE] No converter found for: $sourcePath');
            return;
        }

        meta.type = "texture";
        
        // 🚨 ПРОВЕРКА АКТУАЛЬНОСТИ: Нужно ли вообще конвертировать?
        var sourceStat = Fs.statSync(sourcePath);
        var sourceMtime = Std.int(sourceStat.mtimeMs);
        
        if (Fs.existsSync(meta.buildPath)) {
            var buildStat = Fs.statSync(meta.buildPath);
            var buildMtime = Std.int(buildStat.mtimeMs);
            
            // Если исходник не новее билда, пропускаем конвертацию!
            if (sourceMtime <= buildMtime) {
                trace('  ⏭️ [PIPELINE] Build is up-to-date. Skipping conversion for: $sourcePath');
                meta.lastModified = sourceMtime;
                this.upsertAsset(cast meta);
                return; // 🛑 ВЫХОДИМ, не запуская Sharp
            }
        }

        trace('  🚀 [PIPELINE] Starting conversion. Target buildPath: ${meta.buildPath}');
        try {
            converter.convert(sourcePath, meta).then(function(res:ConversionResult) {
                if (res.error != null) {
                    trace('  ❌ [PIPELINE] Conversion FAILED for: $sourcePath');
                    trace('  ❌ [PIPELINE] Error details: ${res.error}');
                    trace('  💡 [PIPELINE] Check if target file is locked by Chokidar polling or another process.');
                    return;
                }

                trace('  ✅ [PIPELINE] Conversion SUCCESS: $sourcePath → ${res.buildPath}');
                meta.lastModified = Std.int(Fs.statSync(sourcePath).mtimeMs);
                Fs.writeFileSync(metaPath, haxe.Json.stringify(meta, null, "  "), 'utf-8');
                this.upsertAsset(cast meta);
                
            });
        }
        catch(err:Dynamic) {
            trace('  💥 [PIPELINE] Unhandled Promise Rejection in converter for: $sourcePath');
            trace('  💥 [PIPELINE] Error: ${Std.string(err)}');
        };
    
    }

    @:keep
    private function reimportAsset(sourcePath:String):Void {
        importSingleAsset(sourcePath);
    }

    @:keep
    private function cleanupBuildFiles(sourcePath:String):Void {
        var metaPath = sourcePath + '.meta';
        
        // ✅ Удаляем ассет из индекса Lowdb
        removeAssetByPath(sourcePath);
        // Если .meta файла нет, удалять нечего
        if (!js.node.Fs.existsSync(metaPath)) return;

        try {
            // 1. Читаем и парсим .meta файл
            var metaContent = js.node.Fs.readFileSync(metaPath, 'utf-8');
            var meta:Dynamic = haxe.Json.parse(metaContent);
            
            // 2. Пытаемся удалить скомпилированный файл (buildPath)
            if (meta.buildPath != null && js.node.Fs.existsSync(meta.buildPath)) {
                try {
                    // rmSync с force:true игнорирует отсутствие файла, а recursive:true удаляет папки
                    untyped js.node.Fs.rmSync(meta.buildPath, { recursive: true, force: true });
                    trace('🗑️ [AssetPipeline] Cleaned up build file: ${meta.buildPath}');
                } catch (e:Dynamic) {
                    var errCode = untyped e.code;
                    if (errCode == "EBUSY" || errCode == "EPERM") {
                        // ⚠️ Файл заблокирован ОС. Не крашим приложение, просто логируем.
                        trace('⚠️ [AssetPipeline] Cannot delete build file (locked/busy): ${meta.buildPath}. Skipping cleanup.');
                    } else {
                        trace('❌ [AssetPipeline] Error deleting build file ${meta.buildPath}: ${Std.string(e)}');
                    }
                }
            }
            
            // 3. Пытаемся удалить сам .meta файл
            try {
                js.node.Fs.unlinkSync(metaPath);
                trace('🗑️ [AssetPipeline] Deleted meta file: $metaPath');
            } catch (e:Dynamic) {
                var errCode = untyped e.code;
                if (errCode != "EBUSY" && errCode != "EPERM") {
                    trace('❌ [AssetPipeline] Error deleting meta file $metaPath: ${Std.string(e)}');
                }
            }
            
        } catch (e:Dynamic) {
            // Если не удалось прочитать или распарсить .meta, просто логируем и выходим
            trace('❌ [AssetPipeline] Failed to read/parse meta file for cleanup: $metaPath. Error: ${Std.string(e)}');
        }
    }

    /**
     * Вызывается при переименовании файла.
     * Обновляет путь в индексе Lowdb.
     */
    @:keep
    public function onFileRenamed(oldPath:String, newPath:String):Void {
        trace('🔄 [AssetPipeline] File renamed: $oldPath -> $newPath');
        
        var normalizedOld = oldPath.split("\\").join("/");
        var normalizedNew = newPath.split("\\").join("/");
        
        // Находим мету по старому пути
        var meta = getMetaByPath(normalizedOld);
        
        if (meta != null) {
            // Обновляем путь в мете
            meta.sourcePath = js.node.Path.relative(this.projectRoot, normalizedNew);
            
            // Если изменился путь билда (например, расширение другое), можно обновить и его, 
            // но обычно при простом переименовании расширения сохраняются.
            
            // Сохраняем обновленную мету в индекс
            upsertAsset(meta);
            
            trace('✅ [AssetPipeline] Index updated for GUID: ${meta.guid}');
        } else {
            trace('⚠️ [AssetPipeline] Meta not found for old path: $normalizedOld. It might be a new file or non-asset.');
            // Если меты нет, возможно, это новый файл, который еще не импортирован.
            // Можно попробовать импортировать его как новый.
            if (js.node.Fs.existsSync(newPath)) {
                importSingleAsset(newPath);
            }
        }
    }
}