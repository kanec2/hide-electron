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
     */
    public function convert(sourcePath:String, meta:AssetMeta):Promise<ConversionResult> {
        return untyped __js__("new Promise(async (resolve, reject) => {
            try {
                const sharp = require('sharp');
                const fs = require('fs');
                const path = require('path');
                
                // Убеждаемся, что папка Build существует
                const buildDir = path.dirname(meta.buildPath);
                if (!fs.existsSync(buildDir)) {
                    fs.mkdirSync(buildDir, { recursive: true });
                }
                
                let pipeline = sharp(sourcePath);
                
                // Применяем настройки из .meta
                const settings = meta.settings || {};
                
                // Resize если указан maxSize
                if (settings.maxSize) {
                    pipeline = pipeline.resize(settings.maxSize, settings.maxSize, { 
                        fit: 'inside', 
                        withoutEnlargement: true 
                    });
                }
                
                // Формат вывода (по умолчанию webp)
                const format = settings.format || 'webp';
                const quality = settings.quality || 80;
                
                if (format === 'webp') {
                    pipeline = pipeline.webp({ quality: quality });
                } else if (format === 'png') {
                    pipeline = pipeline.png({ compressionLevel: 9 });
                } else if (format === 'jpeg' || format === 'jpg') {
                    pipeline = pipeline.jpeg({ quality: quality });
                }
                
                // Сохраняем результат
                await pipeline.toFile(meta.buildPath);
                
                // Получаем метаданные выходного файла
                const outputMeta = await sharp(meta.buildPath).metadata();
                
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
                
            } catch (err) {
                reject(err);
            }
        })");
    }
    
    /**
     * Генерирует base64 превью для Asset Browser.
     */
    public function getPreview(sourcePath:String, ?size:Int):Promise<String> {
        final previewSize = size != null ? size : DEFAULT_PREVIEW_SIZE;
        
        return untyped __js__("new Promise(async (resolve, reject) => {
            try {
                const sharp = require('sharp');
                
                const buffer = await sharp(sourcePath)
                    .resize(previewSize, previewSize, { 
                        fit: 'inside', 
                        withoutEnlargement: true 
                    })
                    .toBuffer();
                
                const base64 = buffer.toString('base64');
                resolve(`data:image/webp;base64,${base64}`);
                
            } catch (err) {
                reject(err);
            }
        })");
    }
}