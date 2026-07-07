package hide.engine.domain.services;
import h3d.mat.Texture;
import hx.injection.Service;

/**
 * Порт для загрузки ресурсов (меши, текстуры).
 * Реализуется в infrastructure (через IFileSystem IDE или напрямую).
 */
interface IResourceLoader extends Service {
    function loadMesh(path:String):Dynamic;
    function loadTexture(path:String):Null<Texture>;
}