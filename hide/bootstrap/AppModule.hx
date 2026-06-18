package hide.bootstrap;

import hide.presentation.controllers.ToolbarController;
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
import hide.infrastructure.platform.electron.*;
// Добавьте заглушки для остальных, если их еще нет
#end
import hide.infrastructure.external.GoldenLayoutAdapter;
// Application
import hide.application.services.WindowService;
import hide.application.services.MenuService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.application.services.PluginRegistry;

//import hide.application.integration.SceneEditorService;
// Commands (Use Cases)
import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;
import hide.application.commands.SaveLayoutUseCase;
import hide.application.commands.CloseProjectUseCase;
import hide.application.commands.OpenViewUseCase;

import hide.presentation.controllers.MenuController;
import hide.presentation.controllers.WindowController;
// Presentation
import hide.presentation.Ide;
import hide.engine.bootstrap.EngineModule;


// Подключаем extension-методы для красивого синтаксиса (addSingleton и т.д.)
using hx.injection.ServiceExtensions;

class AppModule {
    /**
     * Настраивает все зависимости приложения.
     * Этот метод не создает экземпляры, а только описывает правила их создания.
     */
    public static function configure(collection:ServiceCollection):Void {
        // === 1. Платформа ===
        #if electron
        collection.addSingleton(ElectronIpcBridge);
        collection.addSingleton(IFileSystem, ElectronFileSystemAdapter);
        collection.addSingleton(IFileDialog, ElectronFileDialogAdapter);
        collection.addSingleton(IWindowManager, ElectronWindowAdapter);
        collection.addSingleton(IPlatform, ElectronPlatformAdapter);
        #end
        
        // === 2. Layout Engine ===
        collection.addSingleton(ILayoutEngine, GoldenLayoutAdapter);
        
        // === 3. Shared ===
        collection.addSingleton(IEventBus, EventBusImpl);
        collection.addSingleton(ViewRegistry);
        collection.addSingleton(PluginRegistry);
        
        // === 4. ДВИЖОК (отдельная подсистема!) ===
        EngineModule.configure(collection);  // ← Вызываем модуль движка
        
        // === 5. Application services ===
        collection.addSingleton(WindowService);
        collection.addSingleton(MenuService);
        collection.addSingleton(PluginManager);
        
        // === 6. Мост между IDE и движком ===
//        collection.addSingleton(SceneEditorService);
        
        // === 7. Controllers ===
        collection.addSingleton(MenuController);
        collection.addSingleton(WindowController);
        collection.addSingleton(ToolbarController);
        
        // === 8. Use Cases ===
        collection.addSingleton(LoadProjectUseCase);
        collection.addSingleton(SetFullscreenUseCase);
        
        // === 9. Presentation ===
        collection.addSingleton(Ide);
    }
}