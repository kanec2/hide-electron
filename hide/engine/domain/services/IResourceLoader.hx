package hide.engine.domain.services;

/**
 * Порт для загрузки ресурсов (меши, текстуры).
 * Реализуется в infrastructure (через IFileSystem IDE или напрямую).
 */
interface IResourceLoader {
    function loadMesh(path:String):Dynamic;
    function loadTexture(path:String):Dynamic;
}