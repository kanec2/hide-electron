package hide.infrastructure.di;

import hx.injection.ServiceCollection;
import hide.shared.types.IEventBus;
import hide.shared.types.EventBusImpl;
import hide.domain.services.IFileSystem;
import hide.infrastructure.platform.electron.ElectronFileSystemAdapter;
// ... импорты всех ваших сервисов и use-case-ов

// Подключаем extension-методы для красивого синтаксиса (addSingleton и т.д.)
using hx.injection.ServiceExtensions;

class AppModule {
    /**
     * Настраивает все зависимости приложения.
     * Этот метод не создает экземпляры, а только описывает правила их создания.
     */
    public static function configure(collection:ServiceCollection):Void {
        
        // 1. Инфраструктура (Платформенно-зависимые реализации)
        #if electron
        collection.addSingleton(IFileSystem, ElectronFileSystemAdapter);
        // collection.addSingleton(IWindowManager, ElectronWindowAdapter);
        #elseif nw
        // collection.addSingleton(IFileSystem, NwFileSystemAdapter);
        #else
        // collection.addSingleton(IFileSystem, StubFileSystemAdapter);
        #end

        // 2. Ядро и Shared-типы
        collection.addSingleton(IEventBus, EventBusImpl);
        collection.addSingleton(ViewRegistry);
        collection.addSingleton(PluginRegistry);

        // 3. Сервисы приложения (Singleton, так как хранят состояние)
        collection.addSingleton(WindowService);
        collection.addSingleton(MenuService);
        collection.addSingleton(PluginManager);

        // 4. Use Cases (Transient, чтобы каждый вызов был чистым, 
        // или Singleton, если они полностью stateless и тяжелые)
        collection.addTransient(LoadProjectUseCase);
        collection.addTransient(OpenViewUseCase);
        collection.addTransient(SetFullscreenUseCase);
        collection.addTransient(SaveLayoutUseCase);
        collection.addTransient(CloseProjectUseCase);
        collection.addTransient(AddRecentProjectUseCase);
        collection.addTransient(ClearRecentProjectsUseCase);
        collection.addTransient(SetRendererUseCase);

        // 5. Регистрация самого главного класса
        collection.addSingleton(Ide);
    }
}