%%{init: {'theme': 'base'}}%%

sequenceDiagram
    participant User
    participant MenuCtrl as MenuController
    participant Ide as Ide (Presentation)
    participant LoadUC as LoadProjectUseCase
    participant ProjectSvc as ProjectService
    participant IFS as «interface» IFileSystem
    participant EFS as ElectronFileSystemAdapter
    participant NodeFS as node:fs (External)
    participant EventBus as IEventBus
    participant StatusBar as StatusBar (UI)
    
    Note over User,StatusBar: 🔄 Сценарий: Пользователь открывает проект
    
    User->>MenuCtrl: Click "Open Project"
    MenuCtrl->>Ide: onMenuOpenProject()
    
    Ide->>IFileDialog: showOpen({filters: ["json"]})
    IFileDialog-->>Ide: Promise.resolve("/path/to/project")
    
    Ide->>LoadUC: execute(new FilePath("/path/to/project"))
    
    activate LoadUC
    LoadUC->>IFS: exists(path)
    IFS-->>LoadUC: true
    
    LoadUC->>IFS: readText(path + "/project.json")
    
    activate EFS
    EFS->>NodeFS: readFileSync("/path/to/project/project.json", "utf-8")
    NodeFS-->>EFS: '{"id":"myproj","name":"My Project"}'
    EFS-->>IFS: json string
    deactivate EFS
    
    IFS-->>LoadUC: json string
    LoadUC->>ProjectConfigParser: parse(json)
    ProjectConfigParser-->>LoadUC: ProjectConfig object
    
    LoadUC->>Project: new Project(config.id, config.name, path)
    
    LoadUC->>IResourceLoader: loadResources(config.resources)
    IResourceLoader-->>LoadUC: Promise.resolve([Resource...])
    
    LoadUC->>Project: addResource(r) for each
    LoadUC->>Project: markSaved()
    
    LoadUC->>EventBus: publish(new ProjectLoaded(project, timestamp))
    
    EventBus->>Ide: on(ProjectLoaded)
    Ide->>StatusBar: showMessage("Project loaded: My Project")
    Ide->>WindowService: setTitle("My Project - HIDE")
    
    LoadUC-->>Ide: Promise.resolve(Success(project))
    deactivate LoadUC
    
    Ide-->>MenuCtrl: (async complete)
    MenuCtrl-->>User: UI updated