// hide/engine/infrastructure/HeapsResourceLoader.hx
package hide.engine.infrastructure;
import hide.engine.domain.services.IResourceLoader;
import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import h3d.mat.Texture;
import haxe.io.Bytes;
import hx.injection.Service;

/**
Реализация IResourceLoader через IFileSystem.
Загружает текстуры из файловой системы и конвертирует в h3d.mat.Texture.
*/
class HeapsResourceLoader implements IResourceLoader implements Service {
    private var fileSystem:IFileSystem;
    
    // Кэш текстур для повторного использования
    private var textureCache:Map<String, Texture>;
    
    public function new(fileSystem:IFileSystem) {
        this.fileSystem = fileSystem;
        this.textureCache = new Map();
    }
    
    public function loadMesh(path:String):Dynamic {
        // TODO: загрузка мешей
        trace('⚠️ [HeapsResourceLoader] loadMesh not implemented: $path');
        return null;
    }
    
    /**
     * Загружает текстуру из файловой системы.
     * Использует кэш для повторного использования.
     */
    public function loadTexture(path:String):Null<Texture> {
        // Проверяем кэш
        if (textureCache.exists(path)) {
            trace('📦 [HeapsResourceLoader] Texture from cache: $path');
            return textureCache.get(path);
        }
        
        try {
            // Читаем бинарный файл через IFileSystem
            var bytes:Bytes = fileSystem.readBinary(new FilePath(path));
            
            // Конвертируем Bytes в h3d.mat.Texture
            var texture = createTextureFromBytes(path, bytes);
            
            if (texture != null) {
                // Сохраняем в кэш
                textureCache.set(path, texture);
                trace('🖼️ [HeapsResourceLoader] Texture loaded: $path (${texture.width}x${texture.height})');
            }
            
            return texture;
        } catch (e:Dynamic) {
            trace('❌ [HeapsResourceLoader] Failed to load texture: $path - $e');
            return null;
        }
    }
    
    /**
     * Конвертирует Bytes в h3d.mat.Texture.
     * Использует hxd.res.Any для автоматического определения формата.
     */
    private function createTextureFromBytes(path:String, bytes:Bytes):Null<Texture> {
        try {
            // hxd.res.Any автоматически определяет формат по расширению
            var res = hxd.res.Any.fromBytes(path, bytes);
            var image = res.toImage();
            var texture = image.toTexture();
            return texture;
        } catch (e:Dynamic) {
            trace('❌ [HeapsResourceLoader] Failed to convert bytes to texture: $e');
            return null;
        }
    }
    
    /**
     * Очищает кэш текстур.
     */
    public function clearCache():Void {
        for (tex in textureCache) {
            if (tex != null) tex.dispose();
        }
        textureCache.clear();
        trace('🗑️ [HeapsResourceLoader] Texture cache cleared');
    }
    
    public function dispose():Void {
        clearCache();
    }
}