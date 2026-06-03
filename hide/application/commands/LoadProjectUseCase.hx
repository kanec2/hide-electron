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
    private var resourceLoader:IResourceLoader;
    private var eventBus:IEventBus;

    public function new(fileSystem:IFileSystem, resourceLoader:IResourceLoader, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.resourceLoader = resourceLoader;
        this.eventBus = eventBus;
    }

    public function execute(projectPath:FilePath):Result<Project, String> {
        try {
            var content = fileSystem.readText(projectPath);
            var project = Project.fromJson(content);
            // Загрузка ресурсов
            resourceLoader.loadProjectResources(project);
            // Публикация
            eventBus.publish(new ProjectLoaded(project));
            return Success(project);
        } catch (e:Dynamic) {
            eventBus.publish(new ErrorOccurred("LoadProjectUseCase", new Error(e)));
            return Failure(e.message);
        }
    }
}