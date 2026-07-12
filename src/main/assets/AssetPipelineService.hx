package src.main.assets;

import src.main.assets.ConversionResult;
import js.lib.Promise;
import js.node.Fs;
import js.node.Path;
import haxe.Json;
import src.main.assets.IAssetConverter;
import src.main.assets.AssetMeta;
import src.main.assets.ConversionResult;
using StringTools;
/**
 * Главный сервис управления ассетами.
 * Отслеживает папку Assets/, создает .meta файлы и запускает конвертацию.
 */
class AssetPipelineService {
    private var registry:AssetTypeRegistry;
    private var projectRoot:String;
    private var assetsPath:String;
    private var watcher:Dynamic; // Chokidar instance
    
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
        this.assetsPath = Path.join(root, "Assets");
        
        // Перезапускаем watcher для новой папки
        stopWatching();
        startWatching();
        
        trace('📂 [AssetPipeline] Project root set to: $root');
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
    
    private function startWatching():Void {
        if (assetsPath == "" || !Fs.existsSync(assetsPath)) {
            trace('⚠️ [AssetPipeline] Assets folder does not exist yet: $assetsPath');
            return;
        }
        
        untyped __js__("
            const chokidar = require('chokidar');
            
            this.watcher = chokidar.watch(this.assetsPath + '/**/*', {
                
                persistent: true,
                awaitWriteFinish: {
                    stabilityThreshold: 500,       // Ждем 500ms после записи
                    pollInterval: 100
                },
                ignoreInitial: false               // Сканируем существующие файлы при старте
            });
            
            this.watcher
                .on('add', (path) => this.onFileAdded(path))
                .on('change', (path) => this.onFileChanged(path))
                .on('unlink', (path) => this.onFileDeleted(path));
                
            console.log('✅ [AssetPipeline] Watcher started on: ' + this.assetsPath);
        ");
    }
    
    private function stopWatching():Void {
        if (watcher != null) {
            untyped watcher.close();
            watcher = null;
            trace(' [AssetPipeline] Watcher stopped');
        }
    }
    
    private function onFileAdded(path:String):Void {
        // Игнорируем .meta файлы — они не импортируются
        if (path.endsWith('.meta')) return;
        
        trace('📥 [AssetPipeline] New file detected: $path');
        importSingleAsset(path);
    }
    
    private function onFileChanged(path:String):Void {
        if (path.endsWith('.meta')) return;
        
        trace('🔄 [AssetPipeline] File changed: $path');
        reimportAsset(path);
    }
    
    private function onFileDeleted(path:String):Void {
        trace('🗑️ [AssetPipeline] File deleted: $path');
        cleanupBuildFiles(path);
    }
    
    /**
     * Импортирует один ассет: создает .meta → конвертирует → обновляет индекс.
     */
    private function importSingleAsset(sourcePath:String):Promise<ConversionResult> {
        return untyped __js__("new Promise(async (resolve, reject) => {
            try {
                const fs = require('fs');
                const path = require('path');
                const { v4: uuidv4 } = require('uuid');
                
                // Проверяем, есть ли уже .meta файл
                const metaPath = sourcePath + '.meta';
                let meta;
                
                if (fs.existsSync(metaPath)) {
                    meta = JSON.parse(fs.readFileSync(metaPath, 'utf-8'));
                } else {
                    // Создаем новый .meta файл
                    const ext = path.extname(sourcePath).toLowerCase();
                    const relativeSource = path.relative(pipeline.projectRoot, sourcePath);
                    const buildDir = path.join(pipeline.projectRoot, 'Build', path.dirname(relativeSource));
                    const baseName = path.basename(sourcePath, ext);
                    const buildPath = path.join(buildDir, baseName + '.webp');
                    
                    meta = {
                        guid: uuidv4(),
                        type: 'texture', // Будет определяться конвертером
                        sourcePath: relativeSource,
                        buildPath: buildPath.replace(/\\\\/g, '/'),
                        settings: {},
                        lastModified: fs.statSync(sourcePath).mtimeMs,
                        version: 1
                    };
                    
                    fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
                    console.log(' [AssetPipeline] Created .meta for: ' + relativeSource);
                }
                
                // Находим подходящий конвертер
                const converter = pipeline.registry.getConverter(sourcePath);
                
                if (!converter) {
                    // Нет конвертера — просто копируем или игнорируем
                    resolve({
                        buildPath: sourcePath,
                        metadata: { skipped: true, reason: 'No converter found' }
                    });
                    return;
                }
                
                // Обновляем тип в .meta
                meta.type = converter.supportedExtensions.includes(path.extname(sourcePath)) 
                    ? 'texture' : 'unknown';
                fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
                
                // Запускаем конвертацию
                const result = await converter.convert(sourcePath, meta);
                
                // Обновляем timestamp
                meta.lastModified = fs.statSync(sourcePath).mtimeMs;
                fs.writeFileSync(metaPath, JSON.stringify(meta, null, 2), 'utf-8');
                
                console.log('✅ [AssetPipeline] Converted: ' + meta.sourcePath + ' → ' + result.buildPath);
                resolve(result);
                
            } catch (err) {
                console.error(' [AssetPipeline] Import failed:', err);
                reject(err);
            }
        })");
    }
    
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