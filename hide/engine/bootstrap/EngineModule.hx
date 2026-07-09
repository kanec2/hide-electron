// engine/bootstrap/EngineModule.hx
package hide.engine.bootstrap;

import hide.engine.infrastructure.SceneViewportController;
import hide.engine.infrastructure.ViewportService;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import hide.engine.infrastructure.ShaderNodeRegistry;
import hx.injection.ServiceCollection;
import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineManager;
import hide.engine.domain.services.IResourceLoader;
import hide.engine.domain.services.IEngineEventBus;
import hide.engine.infrastructure.SceneServiceImpl;
import hide.engine.infrastructure.HeapsEngineManager;
import hide.engine.infrastructure.HeapsResourceLoader;
import hide.engine.infrastructure.EngineEventBusImpl;
using hx.injection.ServiceExtensions;

class EngineModule {
    /**
     * Регистрирует внутренние сервисы движка.
     * Внешние зависимости (IEngineManager, IEngineResourceLoader) 
     * должны быть зарегистрированы ДО вызова этого метода 
     * или переданы через параметры.
     */
    public static function configure(collection:ServiceCollection):Void {
        // Внутренние сервисы движка
        collection.addSingleton(IEngineEventBus, EngineEventBusImpl);
        collection.addSingleton(ISceneService, SceneServiceImpl);
        collection.addSingleton(IEngineManager, HeapsEngineManager);

        // Viewport сервисы
        collection.addSingleton(ViewportService);
        collection.addSingleton(SceneViewportController);
        collection.addSingleton(ShaderPreviewRenderer);

            // Shader Editor сервисы
        collection.addSingleton(ShaderNodeRegistry);

        // initialize embeded ressources
        // ✅ НОВОЕ: ResourceLoader
        collection.addSingleton(IResourceLoader, HeapsResourceLoader);
		hxd.Res.initEmbed();
        // IEngineManager и IEngineResourceLoader НЕ регистрируем здесь —
        // они платформенно-зависимые, их регистрирует AppModule IDE
    }
    
    /**
     * Альтернативный вариант: явная передача внешних зависимостей
     */
     
    public static function configureWith(
        collection:ServiceCollection,
        rendererClass:Class<IEngineManager>,
        resourceLoaderClass:Class<IResourceLoader>
    ):Void {
        collection.addSingleton(IEngineEventBus, EngineEventBusImpl);
        collection.addSingleton(ISceneService, SceneServiceImpl);
        //collection.addSingleton(IEngineManager, rendererClass);
        //collection.addSingleton(IResourceLoader, resourceLoaderClass);
    } 
}