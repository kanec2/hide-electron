package hide.application.commands;

import hide.domain.services.IFileSystem;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ErrorOccurred;
import hide.domain.valueobjects.FilePath;
import hide.domain.entities.Project;
import hide.shared.types.Result;
import hx.injection.*;

class LoadProjectUseCase implements Service {
    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;

    public function new(fileSystem:IFileSystem, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.eventBus = eventBus;
    }

    public function execute(projectPath:FilePath):Result<Project, String> {
        try {
            // 1. Валидация существования файла (Fail-fast)
            if (!fileSystem.exists(projectPath)) {
                var msg = 'Project file not found: ${projectPath.toString()}';
                eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", msg));
                return Failure(msg);
            }
            // 2. Чтение содержимого
            var content = fileSystem.readText(projectPath);
            // 3. Парсинг и валидация структуры (вызовет исключение, если JSON битый или нет поля 'name')
            var project = Project.fromJson(content, projectPath);
            // 4. Уведомление системы об успешной загрузке
            eventBus.publish(ProjectLoaded, new ProjectLoaded(project));

            return Success(project);

        } catch (e:haxe.Exception) {
            // Ловим структурные ошибки (например, от Project.fromJson)
            var errorMsg = 'Failed to load project: ${e.message}';
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
            return Failure(errorMsg);
            
        } catch (e:Dynamic) {
            // Ловим ошибки парсинга JSON или файловые ошибки (для совместимости со старыми версиями Haxe)
            var errorMsg = 'Failed to load project: ${Std.string(e)}';
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
            return Failure(errorMsg);
        }
    }
}