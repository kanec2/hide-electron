// engine/bootstrap/EngineModule.hx
package hide.engine.bootstrap;

import hide.engine.infrastructure.SceneViewportController;
import hide.engine.infrastructure.ViewportService;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import hx.injection.ServiceCollection;
import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IRenderer;
import hide.engine.domain.services.IResourceLoader;
import hide.engine.domain.services.IEngineEventBus;
import hide.engine.infrastructure.SceneServiceImpl;
import hide.engine.infrastructure.HeapsRenderer;
import hide.engine.infrastructure.HeapsResourceLoader;
import hide.engine.infrastructure.EngineEventBusImpl;
// Конкретные реализации выбираются в AppModule IDE

using hx.injection.ServiceExtensions;

class EngineModule {
    /**
     * Регистрирует внутренние сервисы движка.
     * Внешние зависимости (IRenderer, IEngineResourceLoader) 
     * должны быть зарегистрированы ДО вызова этого метода 
     * или переданы через параметры.
     */
    public static function configure(collection:ServiceCollection):Void {
        // Внутренние сервисы движка
        collection.addSingleton(IEngineEventBus, EngineEventBusImpl);
        collection.addSingleton(ISceneService, SceneServiceImpl);
        collection.addSingleton(IRenderer, HeapsRenderer);
        collection.addSingleton(ViewportService);  // ← НОВОЕ
        collection.addSingleton(SceneViewportController); // ← НОВОЕ
        collection.addSingleton(ShaderPreviewRenderer); // ← НОВОЕ
        // initialize embeded ressources
        // ✅ НОВОЕ: ResourceLoader
        collection.addSingleton(IResourceLoader, HeapsResourceLoader);
		hxd.Res.initEmbed();
        // IRenderer и IEngineResourceLoader НЕ регистрируем здесь —
        // они платформенно-зависимые, их регистрирует AppModule IDE
    }
    
    /**
     * Альтернативный вариант: явная передача внешних зависимостей
     */
     
    public static function configureWith(
        collection:ServiceCollection,
        rendererClass:Class<IRenderer>,
        resourceLoaderClass:Class<IResourceLoader>
    ):Void {
        collection.addSingleton(IEngineEventBus, EngineEventBusImpl);
        collection.addSingleton(ISceneService, SceneServiceImpl);
        //collection.addSingleton(IRenderer, rendererClass);
        //collection.addSingleton(IResourceLoader, resourceLoaderClass);
    } 
}