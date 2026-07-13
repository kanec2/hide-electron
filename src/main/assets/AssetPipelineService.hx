package src.main.assets;

import src.main.assets.ConversionResult;
import js.lib.Promise;
import js.node.Fs;
import js.node.Path;
import haxe.Json;
import src.main.assets.IAssetConverter;
import src.main.assets.AssetMeta;
import src.main.assets.ConversionResult;
import chokidar.Chokidar; // <-- Импортируем из библиотеки
import chokidar.WatchOptions;
import chokidar.FSWatcher;
import chokidar.AwaitWriteFinishOptions;
import haxe.ds.Either; // <-- Добавь этот импорт
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
        
        stopWatching();
        startWatching();
        
        trace('📂 [AssetPipeline] Project root set to: $normalizedRoot');
        trace('   Watching: $assetsPath');
    }
    
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
    
    /**
     * Получает метаданные ассета по GUID.
     */
    public function getMeta(guid:String):Null<AssetMeta> {
        if (projectRoot == "") return null;
        
        // В реальном проекте здесь будет поиск в asset-index.json
        // Для MVP ищем .meta файл рекурсивно (медленно, но работает)
        return findMetaByGuid(assetsPath, guid);
    }
    
    // === PRIVATE METHODS ===
    
    // hide/main/assets/AssetPipelineService.hx

    // hide/main/assets/AssetPipelineService.hx

    private function startWatching():Void {
        if (assetsPath == "" || !Fs.existsSync(assetsPath)) {
            trace('⚠️ [AssetPipeline] Assets folder does not exist yet: $assetsPath');
            try {
                untyped __js__("require('fs').mkdirSync(this.assetsPath, { recursive: true })");
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
        this.watcher.on('all', function(event, path) {
            trace('🔍 [Chokidar ALL] Event: ' + event + ' | Path: ' + path);
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
     * Вызывается один раз после того, как Chokidar просканировал все существующие файлы.
     */
    @:keep
    public function onInitialScanComplete():Void {
        // Ручная индексация больше не нужна.
        // Chokidar с ignoreInitial: false уже выдал события 'add' для всех существующих файлов.
        trace('✅ [AssetPipeline] Initial scan complete. System ready.');
    }

    

    @:keep
    private function onFileAdded(path:String):Void {
        // Игнорируем .meta файлы — они не импортируются
        if (path.endsWith('.meta')) return;
        
        trace('📥 [AssetPipeline] New file detected: $path');
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
        trace('🗑️ [AssetPipeline] File deleted: $path');
        cleanupBuildFiles(path);
    }
    
    /**
     * Импортирует один ассет: создает .meta → конвертирует → обновляет индекс.
     */
    @:keep
    public function importSingleAsset(sourcePath:String):Void {
        var metaPath = sourcePath + '.meta';
        var fs = untyped __js__("require('fs')");
        
        //var pathLib = untyped __js__("require('path')");
        
        var ext = js.node.Path.extname(sourcePath).toLowerCase();
        var relativeSource = js.node.Path.relative(this.projectRoot, sourcePath);
        
        // Определяем путь для сборки
        var buildDir = js.node.Path.join(this.projectRoot, 'Build', js.node.Path.dirname(relativeSource));
        var baseName = js.node.Path.basename(sourcePath, ext);
        var buildPath = js.node.Path.join(buildDir, baseName + '.webp');

        var meta:Dynamic = null;

        // 1. Работа с файловой системой и .meta (в JS блоке)
        untyped __js__("
            if (fs.existsSync(metaPath)) {
                meta = JSON.parse(fs.readFileSync(metaPath, 'utf-8'));
            } else {
                meta = {
                    guid: require('uuid').v4(),
                    type: 'texture',
                    sourcePath: relativeSource,
                    buildPath: buildPath.replace(/\\\\\\\\/g, '/'),
                    settings: {},
                    lastModified: fs.statSync(sourcePath).mtimeMs,
                    version: 1
                };
                
                if (!fs.existsSync(buildDir)) {
                    fs.mkdirSync(buildDir, { recursive: true });
                }
                
                fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
                console.log(' [AssetPipeline] Created .meta for: ' + relativeSource);
            }
        ");

        // 2. Вызов конвертера на чистом Haxe
        var converter = registry.getConverter(sourcePath);
        
        if (converter == null) {
            trace('⚠️ [AssetPipeline] No converter found for: $sourcePath');
            return;
        }

        // Обновляем тип в мета-данных
        meta.type = "texture"; 
        
        // Запускаем конвертацию. 
        // ВАЖНО: Если converter.convert возвращает Promise, нам нужно его обработать.
        // Предположим, что он возвращает Future<ConversionResult> или Promise.
        
        var resultPromise = converter.convert(sourcePath, meta);
        
        // Обрабатываем результат асинхронно
        untyped __js__("
            resultPromise.then(function(res) {
                // Проверяем, что вернул конвертер
                var finalSource = res.sourcePath != null ? res.sourcePath : sourcePath;
                var finalBuild = res.buildPath != null ? res.buildPath : res; // Если вернул просто строку
                
                console.log('✅ [AssetPipeline] Converted: ' + finalSource + ' → ' + finalBuild);
                
                meta.lastModified = fs.statSync(sourcePath).mtimeMs;
                fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
            }).catch(function(err) {
                console.error('❌ [AssetPipeline] Conversion failed:', err);
            });
        ");
    }

    @:keep
    private function reimportAsset(sourcePath:String):Void {
        importSingleAsset(sourcePath);
    }
    
    private function cleanupBuildFiles(sourcePath:String):Void {
        untyped __js__("
            const fs = require('fs');
            const path = require('path');
            
            const metaPath = sourcePath + '.meta';
            if (fs.existsSync(metaPath)) {
                const meta = JSON.parse(fs.readFileSync(metaPath, 'utf-8'));
                if (meta.buildPath && fs.existsSync(meta.buildPath)) {
                    fs.unlinkSync(meta.buildPath);
                    console.log('️ [AssetPipeline] Cleaned up build file: ' + meta.buildPath);
                }
                fs.unlinkSync(metaPath);
            }
        ");
    }
    
    /**
     * Рекурсивный поиск .meta файла по GUID (для MVP).
     * В продакшене заменить на загрузку asset-index.json в RAM.
     */
    private function findMetaByGuid(dir:String, guid:String):Null<AssetMeta> {
        if (!Fs.existsSync(dir)) return null;
        
        var entries = Fs.readdirSync(dir);
        for (entry in entries) {
            var fullPath = Path.join(dir, entry);
            var stat = Fs.statSync(fullPath);
            
            if (stat.isDirectory() && entry != "node_modules" && entry != ".git") {
                var result = findMetaByGuid(fullPath, guid);
                if (result != null) return result;
            } else if (entry.endsWith('.meta')) {
                try {
                    var content = Fs.readFileSync(fullPath, { encoding: "utf-8" });
                    var meta:AssetMeta = Json.parse(content);
                    if (meta.guid == guid) return meta;
                } catch (_) {}
            }
        }
        
        return null;
    }
}