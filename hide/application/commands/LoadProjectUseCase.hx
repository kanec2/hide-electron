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
            var content = fileSystem.readText(projectPath);
            var data = haxe.Json.parse(content);
            var projectName = data.name != null ? data.name : "Unnamed Project";
            var project = new Project("id-1", projectName, projectPath);
            
            eventBus.publish(ProjectLoaded, new ProjectLoaded(project));
            return Success(project);
        } catch (e:Dynamic) {
            var errorMsg = Std.string(e);
            eventBus.publish(ErrorOccurred, new ErrorOccurred("LoadProjectUseCase", errorMsg));
            return Failure(errorMsg);
        }
    }
}