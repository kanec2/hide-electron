package hide.infrastructure.di;

import hx.injection.ServiceCollection;
import hide.shared.types.IEventBus;
import hide.shared.types.EventBusImpl;

// Domain
import hide.domain.services.IFileSystem;
import hide.domain.services.IWindowManager;
import hide.domain.services.ILayoutEngine;
import hide.domain.services.IAppInfo;
import hide.domain.services.IPlatform;
import hide.domain.services.IFileDialog;

// Infrastructure (Electron)
#if electron
import hide.infrastructure.platform.electron.ElectronFileSystemAdapter;
import hide.infrastructure.platform.electron.*;
// Добавьте заглушки для остальных, если их еще нет
#end

// Application
import hide.application.services.WindowService;
import hide.application.services.MenuService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.application.services.PluginRegistry;

// Commands (Use Cases)
import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;
import hide.application.commands.SaveLayoutUseCase;
import hide.application.commands.CloseProjectUseCase;
import hide.application.commands.OpenViewUseCase;

// Presentation
import hide.presentation.Ide;

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
        // 1. Регистрируем IPC Bridge как Singleton
        collection.addSingleton(ElectronIpcBridge);
        collection.addSingleton(IFileSystem, ElectronFileSystemAdapter);
        collection.addSingleton(IFileDialog, ElectronFileDialogAdapter);
        collection.addSingleton(IWindowManager, ElectronWindowAdapter);
        collection.addSingleton(IPlatform, ElectronPlatformAdapter);
        // TODO: Добавить ElectronPlatformAdapter, ElectronFileDialogAdapter и IAppInfoAdapter
        #elseif nw
        // collection.addSingleton(IFileSystem, NwFileSystemAdapter);
        #else
        // Временные заглушки для веб-версии или тестов
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
        collection.addSingleton(LoadProjectUseCase);
        //collection.addSingleton(OpenViewUseCase);
        collection.addSingleton(SetFullscreenUseCase);
        //collection.addSingleton(SaveLayoutUseCase);
        //collection.addSingleton(CloseProjectUseCase);
       // collection.addTransient(AddRecentProjectUseCase);
        //collection.addTransient(ClearRecentProjectsUseCase);
        //collection.addTransient(SetRendererUseCase);

        // 5. Регистрация самого главного класса
        collection.addSingleton(Ide);
    }
}