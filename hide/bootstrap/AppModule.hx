package hide.bootstrap;

import hide.domain.services.ILanguageServer;
import hide.presentation.modules.ConsoleModule;
import hide.presentation.modules.PropertiesModule;
import hide.presentation.modules.EditorModule;
import hide.presentation.modules.ProjectModule;
import hide.presentation.modules.GameModule;
import hide.presentation.modules.ShaderEditorModule;
import hide.presentation.modules.WelcomeModule;
import hide.presentation.modules.HierarchyModule;
import hide.presentation.modules.SceneModule;
import hide.presentation.modules.InspectorModule;
import hide.presentation.modules.*;
import hide.application.services.IViewModule;
import hide.application.services.ShaderHistoryService;
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
import hide.domain.services.IProjectManager;
// Infrastructure (Electron)
#if electron
import hide.infrastructure.platform.electron.*;
#end
import hide.infrastructure.external.GoldenLayoutAdapter;
// Application
import hide.application.services.WindowService;
import hide.application.services.MenuService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.application.services.PluginRegistry;
import hide.application.services.ProjectService;
import hide.application.integration.SceneEditorService;
// Commands (Use Cases)
import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;
import hide.application.commands.SaveLayoutUseCase;
import hide.application.commands.CloseProjectUseCase;
import hide.application.commands.OpenViewUseCase;
import hide.application.commands.SaveShaderUseCase;
import hide.application.commands.LoadShaderUseCase;
import hide.presentation.controllers.MenuController;
import hide.presentation.controllers.WindowController;
// Presentation
import hide.presentation.Ide;
import hide.engine.bootstrap.EngineModule;
import hide.infrastructure.external.SceneViewFactory;
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
        collection.addSingleton(ILanguageServer, ElectronLanguageServerAdapter);  // ← НОВОЕ
        collection.addSingleton(IProjectManager, ElectronProjectManagerAdapter);
        #end
        
        // === 2. Layout Engine ===
        collection.addSingleton(ILayoutEngine, GoldenLayoutAdapter);
        
        // === 3. Shared ===
        collection.addSingleton(IEventBus, EventBusImpl);
        collection.addSingleton(ViewRegistry);
        collection.addSingleton(PluginRegistry);
        
        // === 4. ДВИЖОК ===
        EngineModule.configure(collection);
        collection.addSingleton(SceneViewFactory);
        
        // === 5. Application services ===
        collection.addSingleton(WindowService);
        collection.addSingleton(MenuService);
        collection.addSingleton(PluginManager);
        collection.addSingleton(ShaderHistoryService);
        collection.addSingleton(ProjectService);
        // === 6. Мост между IDE и движком ===
        collection.addSingleton(SceneEditorService);
        
        // === 7. Controllers ===
        collection.addSingleton(MenuController);
        collection.addSingleton(WindowController);
        collection.addSingleton(ToolbarController);
        
        // === 8. Use Cases ===
        collection.addSingleton(LoadProjectUseCase);
        collection.addSingleton(SetFullscreenUseCase);
        collection.addSingleton(OpenViewUseCase);
        collection.addSingleton(SaveShaderUseCase);
        collection.addSingleton(LoadShaderUseCase);
        
        // === 9. View-модули ===
        collection.addSingleton(IViewModule, SceneModule);
        collection.addSingleton(IViewModule, InspectorModule);
        collection.addSingleton(IViewModule, HierarchyModule);
        collection.addSingleton(IViewModule, WelcomeModule);
        collection.addSingleton(IViewModule, ShaderEditorModule);
        collection.addSingleton(IViewModule, GameModule);
        collection.addSingleton(IViewModule, ProjectModule);
        //collection.addSingleton(IViewModule, EditorModule);
        collection.addSingleton(IViewModule, MonacoEditorModule);
        collection.addSingleton(IViewModule, PropertiesModule);
        collection.addSingleton(IViewModule, ConsoleModule);
        
        // === 10. Presentation ===
        collection.addSingleton(Ide);


    }
}