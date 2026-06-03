%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '11px'}}}%%

graph TD
    Root["hide_js/"]
    
    Root --> Hide["hide/"]
    
    Hide --> Domain["🔷 domain/"]
    Hide --> Application["🟩 application/"]
    Hide --> Presentation["🟨 presentation/"]
    Hide --> Infrastructure["🟥 infrastructure/"]
    Hide --> Shared["⚪ shared/"]
    
    %% DOMAIN
    Domain --> DomainEnt["entities/"]
    Domain --> DomainVO["valueobjects/"]
    Domain --> DomainEnum["enums/"]
    Domain --> DomainPorts["services/ (ports)"]
    Domain --> DomainEx["exceptions/"]
    
    DomainEnt --> Project["Project.hx"]
    DomainEnt --> Resource["Resource.hx"]
    DomainEnt --> Database["Database.hx"]
    
    DomainVO --> FilePath["FilePath.hx<br/>abstract class String"]
    DomainVO --> ResourceId["ResourceId.hx"]
    
    DomainEnum --> ResourceType["ResourceType.hx<br/>enum { Texture, Model, Shader }"]
    DomainEnum --> WindowEvent["WindowEvent.hx<br/>enum { Focus, Blur, Resize }"]
    
    DomainPorts --> IWindow["IWindowManager.hx<br/>interface"]
    DomainPorts --> IFS["IFileSystem.hx<br/>interface"]
    DomainPorts --> IClip["IClipboardService.hx<br/>interface"]
    
    %% APPLICATION
    Application --> AppUC["usecases/"]
    Application --> AppSvc["services/"]
    Application --> AppEv["events/"]
    Application --> AppDTO["dto/"]
    
    AppUC --> LoadUC["LoadProjectUseCase.hx"]
    AppUC --> FullscreenUC["SetFullscreenUseCase.hx"]
    
    AppSvc --> WindowSvc["WindowService.hx"]
    AppSvc --> MenuSvc["MenuService.hx"]
    
    AppEv --> ProjectLoaded["ProjectLoaded.hx"]
    
    AppDTO --> MenuItemDto["MenuItemDto.hx<br/>typedef"]
    
    %% PRESENTATION
    Presentation --> PresUI["ui/"]
    Presentation --> PresViews["views/"]
    Presentation --> PresCtrl["controllers/"]
    Presentation --> PresIde["Ide.hx<br/>(thin controller)"]
    
    PresUI --> View["View.hx<br/>abstract class"]
    PresUI --> Element["Element.hx<br/>jQuery wrapper"]
    
    PresViews --> ModelView["ModelView.hx<br/>extends View<ModelState>"]
    PresViews --> CdbView["CdbTableView.hx"]
    
    PresCtrl --> MenuCtrl["MenuController.hx"]
    
    %% INFRASTRUCTURE
    Infrastructure --> InfraPlat["platform/"]
    Infrastructure --> InfraPersist["persistence/"]
    Infrastructure --> InfraExt["external/"]
    Infrastructure --> InfraCfg["config/"]
    
    InfraPlat --> Electron["electron/"]
    InfraPlat --> Nwjs["nwjs/"]
    
    Electron --> EWindow["ElectronWindowAdapter.hx"]
    Electron --> EFS["ElectronFileSystemAdapter.hx"]
    Electron --> EIpc["ElectronIpcBridge.hx"]
    
    Nwjs --> NWWindow["NwWindowAdapter.hx"]
    
    InfraExt --> GL["GoldenLayoutAdapter.hx"]
    InfraExt --> Monaco["MonacoEditorAdapter.hx"]
    
    %% SHARED
    Shared --> SharedUtils["utils/"]
    Shared --> SharedTypes["types/"]
    
    SharedUtils --> PathUtils["PathUtils.hx"]
    SharedTypes --> Result["Result.hx<br/>enum { Success(T), Failure(E) }"]
    
    classDef domain fill:#e3f2fd,stroke:#1976d2
    classDef application fill:#e8f5e9,stroke:#388e3c
    classDef presentation fill:#f3e5f5,stroke:#7b1fa2
    classDef infrastructure fill:#fff3e0,stroke:#f57c00
    classDef shared fill:#f5f5f5,stroke:#616161
    
    class Domain,DomainEnt,DomainVO,DomainEnum,DomainPorts,DomainEx domain
    class Application,AppUC,AppSvc,AppEv,AppDTO application
    class Presentation,PresUI,PresViews,PresCtrl,PresIde presentation
    class Infrastructure,InfraPlat,InfraPersist,InfraExt,InfraCfg infrastructure
    class Shared,SharedUtils,SharedTypes shared