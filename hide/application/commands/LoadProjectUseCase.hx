// hide/application/commands/LoadProjectUseCase.hx
package hide.application.commands;

import hide.domain.services.IFileSystem;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ErrorOccurred;
import hide.domain.valueobjects.FilePath;
import hide.domain.entities.Project;
import hx.injection.*;
import tink.core.Future;
import tink.core.Outcome;
using tink.CoreApi;

class LoadProjectUseCase implements Service {
    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;

    public function new(fileSystem:IFileSystem, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.eventBus = eventBus;
    }

    /**
     * Выполняет загрузку проекта.
     * Возвращает Future<Outcome>, что позволяет элегантно обрабатывать ошибки в цепочках вызовов.
     */
    public function execute(projectPath:FilePath):Void {
        try {
            // 1. Валидация существования файла
            if (!fileSystem.exists(projectPath)) {
                var msg = 'Project file not found: ${projectPath.toString()}';
                eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", msg));
                return;
            }

            // 2. Чтение содержимого
            var content = fileSystem.readText(projectPath);
            
            // 3. Парсинг и валидация структуры
            var project = Project.fromJson(content, projectPath);
            
            // 4. Уведомление системы об успешной загрузке
            eventBus.publish(ProjectLoaded, new ProjectLoaded(project));
        } catch (e:haxe.Exception) {
            var errorMsg = 'Failed to load project: ${e.message}';
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
        } catch (e:Dynamic) {
            var errorMsg = 'Failed to load project: ${Std.string(e)}';
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
        }
    }
}
