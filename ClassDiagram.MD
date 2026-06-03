%%{init: {'theme': 'base'}}%%

classDiagram
    %% DOMAIN: Entities
    class Project {
        +String id
        +String name
        +FilePath rootPath
        +addResource(Resource): Void
        +getResource(String): Resource?
        +getResourcesByType(ResourceType): Array~Resource~
        +get isDirty: Bool
    }
    
    class Resource {
        +ResourceId id
        +ResourceType type
        +FilePath path
        +Map~String,Dynamic~ metadata
    }
    
    %% DOMAIN: Value Objects
    class FilePath {
        <<abstract>>
        -String value
        +new(String): FilePath
        +toString(): String
        +join(String): FilePath
        +validate(): Bool
    }
    
    %% DOMAIN: Enums
    class ResourceType {
        <<enumeration>>
        Texture
        Model
        Shader
        Cdb
        Prefab
    }
    
    class WindowEvent {
        <<enumeration>>
        Focus
        Blur
        Resize
        Move
        Maximize
        Close
    }
    
    %% DOMAIN: Ports (Interfaces)
    class IWindowManager {
        <<interface>>
        +resizeBy(Int, Int): Void
        +moveTo(Int, Int): Void
        +setFullscreen(Bool): Void
        +getBounds(): WindowBoundsDto
        +on(WindowEvent, Callback): Void
    }
    
    class IFileSystem {
        <<interface>>
        +exists(FilePath): Bool
        +readText(FilePath): String
        +writeText(FilePath, String): Void
        +listFiles(FilePath, ?Bool): Array~FilePath~
        +getAppDataPath(): FilePath
    }
    
    class IClipboardService {
        <<interface>>
        +setText(String, ?String): Void
        +getText(?String): String
        +hasFormat(String): Bool
    }
    
    %% APPLICATION: Use Cases
    class LoadProjectUseCase {
        -IFileSystem fileSystem
        -IResourceLoader resourceLoader
        -IEventBus eventBus
        +execute(FilePath): Promise~Result~Project, Error~~
    }
    
    class SetFullscreenUseCase {
        -IWindowManager window
        +execute(Bool): Void
    }
    
    %% APPLICATION: Services
    class WindowService {
        -IWindowManager adapter
        +resizeBy(Int, Int): Void
        +moveTo(Int, Int): Void
        +setFullscreen(Bool): Void
    }
    
    class MenuService {
        -IClipboardService clipboard
        +buildFromHtml(String): Array~MenuItemDto~
        +setClipboard(Dynamic, ?String): Void
    }
    
    %% INFRASTRUCTURE: Adapters
    class ElectronWindowAdapter {
        -Dynamic ipcRenderer
        -Dynamic BrowserWindow
        +resizeBy(Int, Int): Void
        +moveTo(Int, Int): Void
        +setFullscreen(Bool): Void
    }
    
    class ElectronFileSystemAdapter {
        -Dynamic fs
        -Dynamic path
        -Dynamic app
        +exists(FilePath): Bool
        +readText(FilePath): String
        +writeText(FilePath, String): Void
    }
    
    %% PRESENTATION: UI
    class View~T~ {
        <<abstract>>
        +container: Element
        +state: T
        +render(): Void
        +update(): Void
        +dispose(): Void
    }
    
    class Ide {
        -ServiceContainer services
        +onMenuOpenProject(): Void
        +onToggleFullscreen(): Void
        +onMenuItemClick(String): Void
    }
    
    %% RELATIONSHIPS
    
    %% Domain entities
    Project "1" *-- "0..*" Resource : contains
    Project ..> FilePath : uses
    Resource ..> ResourceId : uses
    Resource ..> ResourceType : uses
    
    %% Domain ports
    IWindowManager <|.. ElectronWindowAdapter : implements
    IFileSystem <|.. ElectronFileSystemAdapter : implements
    IClipboardService <|.. ElectronClipboardAdapter : implements
    
    %% Application uses Domain
    LoadProjectUseCase --> Project : creates
    LoadProjectUseCase --> IFileSystem : depends
    LoadProjectUseCase --> IResourceLoader : depends
    SetFullscreenUseCase --> IWindowManager : depends
    
    WindowService --> IWindowManager : wraps
    MenuService --> IClipboardService : uses
    
    %% Presentation uses Application
    Ide --> LoadProjectUseCase : invokes
    Ide --> SetFullscreenUseCase : invokes
    Ide --> WindowService : uses
    View <|-- ModelView : extends
    View <|-- PrefabView : extends
    
    %% Shared types
    note for LoadProjectUseCase "Returns Result~Project,Error~\nfrom shared/types/"
    
    classDef domain fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef application fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    classDef presentation fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef infrastructure fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    