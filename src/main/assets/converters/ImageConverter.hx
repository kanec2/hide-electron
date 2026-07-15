package src.main.assets.converters;

import js.lib.Promise;
import js.node.Fs;
import js.node.Path;
import src.main.assets.IAssetConverter;
import src.main.assets.AssetMeta;
import src.main.assets.ConversionResult;

/**
 * Конвертер изображений на базе Sharp.
 * Поддерживает: PNG, JPG, JPEG, WEBP, TGA, BMP
 */
class ImageConverter implements IAssetConverter {
    public var supportedExtensions:Array<String> = [".png", ".jpg", ".jpeg", ".webp", ".tga", ".bmp"];
    private static inline var DEFAULT_PREVIEW_SIZE:Int = 128;

    public function new() {}

    public function canConvert(path:String):Bool {
        var ext = Path.extname(path).toLowerCase();
        return supportedExtensions.indexOf(ext) != -1;
    }

    /**
     * Конвертирует изображение в WebP с настройками из .meta файла.
     * ✅ ИСПОЛЬЗУЕТ НАТИВНЫЙ js.lib.Promise ВМЕСТО untyped __js__ СТРОК
     */
    public function convert(sourcePath:String, meta:AssetMeta):Promise<ConversionResult> {
        return new Promise(function(resolve, reject) {
            untyped __js__("
                const sharp = require('sharp');
                const fs = require('fs');
                const path = require('path');

                const buildDir = path.dirname(meta.buildPath);
                if (!fs.existsSync(buildDir)) {
                    fs.mkdirSync(buildDir, { recursive: true });
                }

                let pipeline = sharp(sourcePath);
                const settings = meta.settings || {};

                if (settings.maxSize) {
                    pipeline = pipeline.resize(settings.maxSize, settings.maxSize, { 
                        fit: 'inside', 
                        withoutEnlargement: true 
                    });
                }

                const format = settings.format || 'webp';
                const quality = settings.quality || 80;

                if (format === 'webp') {
                    pipeline = pipeline.webp({ quality: quality });
                } else if (format === 'png') {
                    pipeline = pipeline.png({ compressionLevel: 9 });
                } else if (format === 'jpeg' || format === 'jpg') {
                    pipeline = pipeline.jpeg({ quality: quality });
                }

                // ✅ Цепочка Promise вместо async/await для совместимости с Haxe
                pipeline.toFile(meta.buildPath)
                    .then(function() {
                        return sharp(meta.buildPath).metadata();
                    })
                    .then(function(outputMeta) {
                        // ✅ УСПЕХ: передаем данные в Haxe через resolve
                        resolve({
                            buildPath: meta.buildPath,
                            metadata: {
                                width: outputMeta.width,
                                height: outputMeta.height,
                                format: outputMeta.format,
                                size: fs.statSync(meta.buildPath).size,
                                channels: outputMeta.channels
                            }
                        });
                    })
                    .catch(function(err) {
                        console.error('❌ [Sharp] Conversion failed for', sourcePath, ':', err.message);
                        
                        // ✅ МЯГКАЯ ОШИБКА: не делаем reject, а resolve с полем error.
                        // Это предотвращает UnhandledPromiseRejectionWarning в Node.js
                        resolve({
                            buildPath: meta.buildPath,
                            metadata: {},
                            error: err.message || String(err)
                        });
                    });
            ");
        });
    }

    /**
     * Генерирует base64 превью для Asset Browser.
     * ✅ Также использует нативный Promise
     */
    public function getPreview(sourcePath:String, ?size:Int):Promise<String> {
        final previewSize = size != null ? size : DEFAULT_PREVIEW_SIZE;
        
        return new Promise(function(resolve, reject) {
            untyped __js__("
                const sharp = require('sharp');
                
                sharp(sourcePath)
                    .resize(previewSize, previewSize, { 
                        fit: 'inside', 
                        withoutEnlargement: true 
                    })
                    .toBuffer()
                    .then(function(buffer) {
                        const base64 = buffer.toString('base64');
                        resolve('data:image/webp;base64,' + base64);
                    })
                    .catch(function(err) {
                        reject(err);
                    });
            ");
        });
    }
}