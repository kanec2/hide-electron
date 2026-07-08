package hide.bootstrap;
import hx.injection.Service;
import hx.injection.ServiceCollection;
import hx.injection.ServiceProvider;
import hide.engine.domain.services.IEngineManager;
import hide.presentation.Ide;
// bootstrap/Application.hx
class Application {
    public static function main():Void {
       // 1. Создаём DI-контейнер
        var collection = new ServiceCollection();
        
        // 2. Регистрируем все зависимости
        AppModule.configure(collection);
        
        // 3. Создаём провайдер
        var provider = collection.createProvider();
        
        // 4. Запускаем IDE
        var ide = provider.getService(Ide);
        var engineManager = provider.getService(IEngineManager);
        engineManager.init();
        ide.startup();  // ← теперь это работает, т.к. startup() публичный
        
        // 5. Загружаем плагины
        //provider.getService(PluginManager).loadAll();
    }
}