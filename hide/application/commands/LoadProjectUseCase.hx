// hide/application/commands/LoadProjectUseCase.hx

package hide.application.commands;

import hide.domain.services.IFileSystem;
import hide.domain.services.IResourceLoader;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ErrorOccurred;
import hide.shared.types.FilePath;
import hide.shared.types.Result;
import hide.shared.types.Success;
import hide.shared.types.Failure;
import hide.domain.entities.Project;

class LoadProjectUseCase {
    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;

    public function new(fileSystem:IFileSystem, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.eventBus = eventBus;
    }

    public function execute(projectPath:FilePath):Result<Project, String> {
        try {
            // 1. Читаем файл (например, project.json или .hide)
            var content = fileSystem.readText(projectPath);
            // 2. Парсим (пока упрощенно, можно использовать haxe.Json.parse)
            var data = haxe.Json.parse(content);
            var projectName = data.name != null ? data.name : "Unnamed Project";
            // 3. Создаем доменную сущность
            var project = new Project("id-1", projectName, projectPath);
            
            // 4. Публикуем событие об успехе
            eventBus.publish(ProjectLoaded, new ProjectLoaded(project));
            
            return Success(project);
        } catch (e:Dynamic) {
            // 5. Публикуем событие об ошибке
            var errorMsg = Std.string(e);
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
            return Failure(errorMsg);
        }
    }
}