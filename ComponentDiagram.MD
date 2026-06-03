%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#e3f2fd', 'primaryBorderColor': '#1976d2', 'primaryTextColor': '#0d47a1', 'lineColor': '#546e7a', 'tertiaryColor': '#fff3e0'}}}%%

graph TB
    %% ============ LAYERS ============
    subgraph Presentation["🟨 PRESENTATION LAYER (UI)"]
        direction TB
        Ide["Ide.hx<br/>(Thin Controller)"]
        
        subgraph UI_Components["ui/"]
            View["View<T><br/>(abstract base)"]
            Element["Element<br/>(DOM wrapper)"]
            MenuBuilder["MenuBuilder<br/>(HTML → Template)"]
            StatusBar["StatusBar"]
            Dialog["Dialog"]
        end
        
        subgraph Views["views/"]
            ModelView["ModelView"]
            PrefabView["PrefabView"]
            CdbTableView["CdbTableView"]
            ScriptView["ScriptEditorView"]
            FXView["FXEditorView"]
        end
        
        subgraph Controllers["controllers/"]
            MenuCtrl["MenuController"]
            KeyCtrl["KeyboardController"]
            DragCtrl["DragDropController"]
        end
    end
    
    subgraph Application["🟩 APPLICATION LAYER (Business Logic)"]
        direction TB
        
        subgraph UseCases["usecases/"]
            LoadProject["LoadProjectUseCase"]
            OpenResource["OpenResourceUseCase"]
            SaveLayout["SaveLayoutUseCase"]
            SetFullscreen["SetFullscreenUseCase"]
            BuildProject["BuildProjectUseCase"]
            ExportDB["ExportDatabaseUseCase"]
        end
        
        subgraph AppServices["services/"]
            WindowSvc["WindowService"]
            MenuSvc["MenuService"]
            LayoutSvc["LayoutService"]
            ProjectSvc["ProjectService"]
            ResourceSvc["ResourceService"]
            ClipboardSvc["ClipboardService"]
        end
        
        subgraph Events["events/"]
            ProjectLoaded["ProjectLoaded"]
            ResourceOpened["ResourceOpened"]
            LayoutChanged["LayoutChanged"]
            ErrorOccurred["ErrorOccurred"]
        end
        
        subgraph DTOs["dto/"]
            WindowBounds["WindowBoundsDto"]
            MenuItemDto["MenuItemDto"]
            ResourceMeta["ResourceMetadataDto"]
        end
    end
    
    subgraph Domain["🔷 DOMAIN LAYER (Core Business)"]
        direction TB
        
        subgraph Entities["entities/"]
            Project["Project"]
            Resource["Resource"]
            Database["Database"]
            LayoutConfig["LayoutConfig"]
            UserSettings["UserSettings"]
        end
        
        subgraph ValueObjects["valueobjects/"]
            FilePath["FilePath<br/>(abstract String)"]
            ResourceId["ResourceId"]
            ScreenBounds["ScreenBounds"]
        end
        
        subgraph Enums["enums/"]
            ResourceType["ResourceType<br/>enum"]
            ViewType["ViewType<br/>enum"]
            WindowEvent["WindowEvent<br/>enum"]
            MenuItemType["MenuItemType<br/>enum"]
        end
        
        subgraph Ports["services/ (Ports)"]
            IWindow["«interface»<br/>IWindowManager"]
            IClipboard["«interface»<br/>IClipboardService"]
            IFileSystem["«interface»<br/>IFileSystem"]
            IResourceLoader["«interface»<br/>IResourceLoader"]
            ILayoutEngine["«interface»<br/>ILayoutEngine"]
            IEventBus["«interface»<br/>IEventBus"]
        end
        
        subgraph Exceptions["exceptions/"]
            ProjectError["ProjectLoadError"]
            ResourceError["ResourceNotFoundError"]
            ConfigError["InvalidConfigError"]
        end
    end
    
    subgraph Infrastructure["🟥 INFRASTRUCTURE LAYER (Adapters)"]
        direction TB
        
        subgraph Platform["platform/"]
            subgraph Electron["electron/"]
                EWindow["ElectronWindowAdapter"]
                EClipboard["ElectronClipboardAdapter"]
                EFileSystem["ElectronFileSystemAdapter"]
                EScreen["ElectronScreenAdapter"]
                EShortcuts["ElectronShortcutAdapter"]
                EIpc["ElectronIpcBridge"]
            end
            
            subgraph NWJS["nwjs/"]
                NWWindow["NwWindowAdapter"]
                NWClipboard["NwClipboardAdapter"]
                NWFileSystem["NwFileSystemAdapter"]
            end
            
            subgraph Web["web/"]
                BrowserWindow["BrowserWindowAdapter"]
                LocalStorage["LocalStorageAdapter"]
            end
        end
        
        subgraph Persistence["persistence/"]
            FSRepo["FileSystemRepository"]
            LSRepo["LocalStorageRepository"]
            MemRepo["MemoryRepository<T>"]
        end
        
        subgraph External["external/"]
            GLAdapter["GoldenLayoutAdapter"]
            MonacoAdapter["MonacoEditorAdapter"]
            HeapsAdapter["HeapsEngineAdapter"]
            jQueryAdapter["jQueryElementAdapter"]
        end
        
        subgraph Config["config/"]
            PkgLoader["PackageJsonLoader"]
            SettingsLoader["UserSettingsLoader"]
            ConfigParser["ProjectConfigParser"]
        end
    end
    
    subgraph Shared["⚪ SHARED (Cross-layer utilities)"]
        Utils["utils/<br/>PathUtils, JsonUtils, AsyncUtils"]
        Types["types/<br/>Result<T,E>, Option<T>"]
        Extensions["extensions/<br/>StringExt, ArrayExt"]
    end
    
    subgraph Tests["🧪 TESTS (Separate)"]
        UnitTests["unit/<br/>MockFileSystem, MockEventBus"]
        IntegrationTests["integration/<br/>ElectronIpcTest"]
        E2ETests["e2e/<br/>IdeStartupTest"]
    end
    
    %% ============ DEPENDENCIES ============
    
    %% Presentation → Application
    Ide --> LoadProject
    Ide --> SetFullscreen
    Ide --> WindowSvc
    Ide --> MenuSvc
    MenuCtrl --> MenuSvc
    KeyCtrl --> WindowSvc
    
    %% Application → Domain
    LoadProject --> Project
    LoadProject --> IFileSystem
    LoadProject --> IResourceLoader
    LoadProject --> IEventBus
    MenuSvc --> IClipboard
    WindowSvc --> IWindow
    LayoutSvc --> ILayoutEngine
    ProjectSvc --> Project
    ResourceSvc --> Resource
    ResourceSvc --> IResourceLoader
    
    %% Domain → (nothing - pure!)
    
    %% Infrastructure → Domain (implementing ports)
    EWindow -.->|implements| IWindow
    EClipboard -.->|implements| IClipboard
    EFileSystem -.->|implements| IFileSystem
    EScreen -.->|implements| IScreenService
    EShortcuts -.->|implements| IShortcutManager
    NWWindow -.->|implements| IWindow
    GLAdapter -.->|implements| ILayoutEngine
    FSRepo -.->|implements| IRepository
    HeapsAdapter -.->|implements| IRenderEngine
    
    %% Infrastructure → External libs
    EWindow --> ElectronIPC["electron.ipcRenderer"]
    EClipboard --> ElectronClip["electron.clipboard"]
    EFileSystem --> NodeFS["node:fs"]
    EFileSystem --> NodePath["node:path"]
    GLAdapter --> GoldenLayoutJS["golden-layout.js"]
    MonacoAdapter --> MonacoJS["monaco-editor"]
    HeapsAdapter --> HeapsJS["heaps/h3d"]
    jQueryAdapter --> jQueryJS["jquery"]
    
    %% Shared used everywhere
    Shared -.- Ide
    Shared -.- LoadProject
    Shared -.- Project
    Shared -.- EFileSystem
    
    %% Tests depend on all layers for mocking
    UnitTests -.- Domain
    UnitTests -.- Application
    IntegrationTests -.- Infrastructure
    E2ETests -.- Presentation
    
    %% ============ DATA FLOW EXAMPLE ============
    
    subgraph DataFlow["🔄 Example: User clicks 'Open Project'"]
        direction LR
        DF1["User clicks menu"] --> DF2["MenuController.onOpenProject()"]
        DF2 --> DF3["LoadProjectUseCase.execute(path)"]
        DF3 --> DF4["IFileSystem.readText(path)"]
        DF4 --> DF5["ElectronFileSystemAdapter"]
        DF5 --> DF6["node:fs.readFileSync()"]
        DF6 --> DF5
        DF5 --> DF4
        DF4 --> DF3
        DF3 --> DF7["ProjectLoaded event"]
        DF7 --> DF8["Ide.subscribe() → update UI"]
        DF8 --> DF9["StatusBar.showMessage()"]
    end
    
    %% ============ STYLING ============
    classDef presentation fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef application fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    classDef domain fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef infrastructure fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef shared fill:#f5f5f5,stroke:#616161,stroke-dasharray: 5 5
    classDef tests fill:#ffebee,stroke:#c62828,stroke-dasharray: 3 3
    
    class Ide,View,Element,MenuBuilder,ModelView,PrefabView presentation
    class LoadProject,WindowSvc,MenuSvc,ProjectLoaded,WindowBounds application
    class Project,FilePath,IWindow,IFileSystem,ResourceType domain
    class EWindow,EFileSystem,GLAdapter,ElectronIPC infrastructure
    class Utils,Types,Extensions shared
    class UnitTests,IntegrationTests tests
    
    linkStyle default stroke:#546e7a,stroke-width:1px