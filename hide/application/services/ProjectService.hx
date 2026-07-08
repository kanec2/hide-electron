package hide.application.services;

import hide.domain.entities.Project;
import hide.domain.services.IFileSystem;
import hide.domain.valueobjects.FilePath;
import hide.shared.types.IEventBus;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ProjectClosed;
import hx.injection.Service;
class ProjectService implements Service {
    private var fileSystem:IFileSystem;
    private var eventBus:IEventBus;
    private var currentProject:Null<Project>;
    public function new(fileSystem:IFileSystem, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.eventBus = eventBus;
    }

    public function getCurrentProject():Null<Project> {
        return currentProject;
    }

    public function loadProject(path:FilePath):Void {
        // TODO: Реализовать загрузку проекта
        trace("ProjectService.loadProject: Not fully implemented");
    }

    public function closeProject():Void {
        currentProject = null;
        eventBus.publish(ProjectClosed, new ProjectClosed());
    }
}