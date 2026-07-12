// hide/application/services/ProjectService.hx
package hide.application.services;

import hide.domain.entities.Project;
import hide.domain.valueobjects.FilePath;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectLoaded;
import hide.infrastructure.platform.electron.ElectronIpcBridge;
import hide.application.commands.LoadProjectUseCase;
import hx.injection.Service;
import tink.core.*;
using tink.CoreApi;
import hide.shared.types.IpcResponse;

class ProjectService implements Service {
//    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;
    private var ipcBridge:ElectronIpcBridge; // <-- Инжектим мост
    private var currentProject:Null<Project>;
    private var loadProjectUseCase:LoadProjectUseCase;

    public function new(loadProjectUseCase:LoadProjectUseCase, ipcBridge:ElectronIpcBridge,eventBus:IEventBus) {
        this.loadProjectUseCase = loadProjectUseCase;
        this.ipcBridge = ipcBridge;
        this.eventBus = eventBus;
        // Подписываемся на успешную загрузку проекта
        eventBus.subscribe(ProjectLoaded, onProjectLoaded);
        //eventBus.subscribe(ProjectClosed, onProjectClosed);
    }

    /**
     * Публичный метод для UI.
     */
    public function openProject(path:FilePath):Void {
        // Просто вызываем UseCase. Он сам опубликует событие при успехе.
        loadProjectUseCase.execute(path);
    }

    private function onProjectLoaded(e:ProjectLoaded):Void {
        currentProject = e.project;
        trace('📂 [ProjectService] Current project set to: ${currentProject.name}');
        
        // ✅ ОТПРАВЛЯЕМ КОМАНДУ НА БЭКЕНД
        initBackendPipeline(currentProject);
    }

    private function initBackendPipeline(project:Project):Void {
        trace('🚀 [ProjectService] Initializing backend services...');
    
        ipcBridge.invokeSafe("asset:init", {
            projectRoot: project.rootPath.toString(),
            assetsFolder: project.assetsPath,
            buildFolder: project.buildPath
        }).handle(function(response:IpcResponse<Dynamic>) {
            if (response != null && response.success) {
                trace('✅ [ProjectService] Backend initialized. Assets path: ${response.data.assetsPath}');
            } else {
                trace('❌ [ProjectService] Backend init failed: ${response != null ? response.error : "Unknown error"}');
            }
        });
    }

/*    private function onProjectClosed(e:ProjectClosed):Void {
        currentProject = null;
        trace('❌ [ProjectService] Current project cleared');
    }*/

    public function getCurrentProject():Null<Project> {
        return currentProject;
    }
    
    public function hasActiveProject():Bool {
        return currentProject != null;
    }
}