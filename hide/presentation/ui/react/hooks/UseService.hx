package hide.presentation.ui.react.hooks;

import hide.engine.infrastructure.ShaderPreviewRenderer;
import hide.engine.infrastructure.ViewportService;
import hide.presentation.Ide;
import hide.application.services.WindowService;
import hide.application.services.MenuService;
import hide.application.services.ViewRegistry;
import hide.application.services.PluginManager;
import hide.shared.types.IEventBus;
import hide.domain.services.ILayoutEngine;
import hide.engine.domain.services.ISceneService;
import hide.domain.services.IFileSystem;
import hide.domain.services.IFileDialog;

/**
 * Статический доступ к сервисам из React-компонентов.
 * Использует глобальный инстанс Ide как Service Locator.
 */
class UseService {
    public static function eventBus():IEventBus {
        return Ide.inst.get_eventBus();
    }
    
    public static function windowService():WindowService {
        return Ide.inst.get_windowService();
    }
    
    public static function menuService():MenuService {
        return Ide.inst.get_menuService();
    }
    
    public static function viewRegistry():ViewRegistry {
        return Ide.inst.get_viewRegistry();
    }
    
    public static function layoutEngine():ILayoutEngine {
        return Ide.inst.get_layoutEngine();
    }

    public static function sceneService():ISceneService {
        return Ide.inst.get_sceneService();
    }
    public static function shaderPreviewRenderer():ShaderPreviewRenderer {
        return Ide.inst.get_shaderPreviewRenderer();
    }
    public static function viewportService():ViewportService {
        return Ide.inst.get_viewportService(); // Убедитесь, что геттер есть в Ide.hx
    }
    public static function fileSystem():IFileSystem {
        return Ide.inst.get_fileSystem();
    }

    public static function fileDialog():IFileDialog {
        return Ide.inst.get_fileDialog();
    }
}