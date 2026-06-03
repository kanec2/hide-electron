package hide.application.usecases;

import hide.domain.entities.Project;
import hide.domain.valueobjects.FilePath;
import hide.domain.services.IFileSystem;
import hide.domain.services.IResourceLoader;
import hide.application.events.ProjectLoaded;
import hide.application.events.ErrorOccurred;
import hide.shared.utils.Result;

/**
 * Use-Case: Загрузка проекта.
 * Оркестрирует загрузку данных, валидацию, инициализацию ресурсов.
 * Не знает ничего про UI или платформу.
 */
class LoadProjectCommand {
    private var fileSystem:IFileSystem;
    private var resourceLoader:IResourceLoader;
    private var eventBus:IEventBus;
    
    public function new(
        fileSystem:IFileSystem,
        resourceLoader:IResourceLoader,
        eventBus:IEventBus
    ) {
        this.fileSystem = fileSystem;
        this.resourceLoader = resourceLoader;
        this.eventBus = eventBus;
    }
    
    /**
     * Выполняет загрузку проекта.
     * @return Promise<Result<Project, Error>> — успех или ошибка
     */
    public function execute(projectPath:FilePath):Promise<Result<Project, Error>> {
        return new Promise(function(resolve, reject) {
            try {
                // 1. Валидация пути
                if (!fileSystem.exists(projectPath)) {
                    throw new FileNotFoundError(projectPath);
                }
                
                // 2. Загрузка конфигурации проекта
                var configPath = projectPath.join("project.json");
                var configJson = fileSystem.readText(configPath);
                var config = ProjectConfigParser.parse(configJson);
                
                // 3. Создание сущности проекта
                var project = new Project(config.id, config.name, projectPath);
                
                // 4. Загрузка ресурсов (асинхронно)
                resourceLoader.loadResources(config.resources)
                    .then(function(resources) {
                        for (r in resources) {
                            project.addResource(r);
                        }
                        project.markSaved();
                        
                        // 5. Публикуем событие об успехе
                        eventBus.publish(new ProjectLoaded(project, Date.now()));
                        
                        resolve(Result.Success(project));
                    })
                    .catchError(function(err) {
                        eventBus.publish(new ErrorOccurred(err, 'LoadProject: ${projectPath}'));
                        resolve(Result.Failure(err));
                    });
                    
            } catch (err:Error) {
                eventBus.publish(new ErrorOccurred(err, 'LoadProject: ${projectPath}'));
                resolve(Result.Failure(err));
            }
        });
    }
}