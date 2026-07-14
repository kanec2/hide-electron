package hide.presentation;

import hide.domain.services.ILanguageServer;
import hide.domain.services.IFileSystem;
import hide.application.services.IViewModule;
import hide.application.services.ShaderHistoryService;
import hide.application.commands.SaveShaderUseCase;
import hide.application.commands.LoadShaderUseCase;
import hide.engine.infrastructure.ShaderPreviewRenderer;
import hide.engine.infrastructure.ShaderNodeRegistry;
import hide.presentation.controllers.ToolbarController;
import hide.presentation.controllers.WindowController;
import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.application.services.ProjectService;
import hide.application.services.AssetBrowserService;
import hide.application.services.ProjectTreeService;

import hide.domain.services.IFileDialog;
import hide.domain.services.IPlatform;
import hide.domain.services.IAppInfo;
import hide.presentation.ui.StatusBar;
import hide.presentation.controllers.MenuController;
import hide.application.integration.SceneEditorService;
import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;
import hide.application.commands.SaveLayoutUseCase;
import hide.application.commands.CloseProjectUseCase;
import hide.application.commands.OpenViewUseCase;
import hide.application.dto.ViewDto;
import hide.domain.valueobjects.DisplayPosition;
import hide.domain.valueobjects.FilePath;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ErrorOccurred;
import hide.shared.events.LayoutChanged;
import hide.shared.events.ProjectClosed;
import hide.shared.events.RecentProjectsUpdated;
import hide.shared.types.IEventBus;
import hide.shared.types.Result;
import hide.domain.services.ILayoutEngine;
import hide.engine.domain.services.ISceneService;
import hide.engine.infrastructure.ViewportService;
import hide.infrastructure.external.SceneViewFactory;
import hx.injection.Service;
import hx.injection.ServiceCollection;
import hx.injection.ServiceProvider;
import tink.core.*;
using tink.CoreApi;
using hx.injection.ServiceExtensions;
using Lambda;
/**
Главный класс IDE.
⚠️ Является Service Locator для React-компонентов,
потому что haxe-react не поддерживает хуки и функциональные компоненты.
Все остальные слои (Application, Domain, Infrastructure)
получают зависимости через DI-контейнер (hx.injection).
*/
@:expose
class Ide implements Service {
    public static var inst(default, null):Ide;
    private var _resizeHandler:Null<js.html.Event->Void>;
    private var views:Array<ViewDto>;
    private var statusBar:StatusBar;
    
    public var currentProjectName(get, never):String;
    private var _currentProject:Null<String>;
    
    private var _projectLoadedUnsub:CallbackLink;
    private var _errorUnsub:CallbackLink;
    private var _layoutChangedUnsub:CallbackLink;
    private var _projectClosedUnsub:CallbackLink;
    
    // Сервисы
    private var windowService:WindowService;
    private var menuService:MenuService;
    private var layoutEngine:ILayoutEngine;
    private var menuController:MenuController;
    private var loadProjectUseCase:LoadProjectUseCase;
    private var setFullscreenUseCase:SetFullscreenUseCase;
    private var openViewUseCase:OpenViewUseCase;
    private var viewRegistry:ViewRegistry;
    private var pluginManager:PluginManager;
    private var eventBus:IEventBus;
    private var fileDialog:IFileDialog;
    private var fileSystem:IFileSystem;
    private var platform:IPlatform;
    private var windowController:WindowController;
    private var toolbarController:ToolbarController;
    private var sceneService:ISceneService;
    private var sceneEditorService:SceneEditorService;
    private var sceneViewFactory:SceneViewFactory;
    private var shaderPreviewRenderer:ShaderPreviewRenderer;
    private var viewportService:ViewportService;
    private var viewModules:Iterable<IViewModule>;
    // Новые сервисы для Shader Editor
    private var shaderNodeRegistry:ShaderNodeRegistry;
    private var shaderHistory:ShaderHistoryService;
    private var saveShader:SaveShaderUseCase;
    private var loadShader:LoadShaderUseCase;
    private var languageServer:ILanguageServer;
    private var projectService:ProjectService;
    private var assetBrowserService:AssetBrowserService;
    private var projectTreeService:ProjectTreeService;
    public function new(
        windowService:WindowService,
        menuService:MenuService,
        loadProjectUseCase:LoadProjectUseCase,
        setFullscreenUseCase:SetFullscreenUseCase,
        openViewUseCase:OpenViewUseCase,
        viewRegistry:ViewRegistry,
        pluginManager:PluginManager,
        eventBus:IEventBus,
        fileDialog:IFileDialog,
        fileSystem:IFileSystem,
        platform:IPlatform,
        layoutEngine:ILayoutEngine,
        menuController:MenuController,
        windowController:WindowController,
        toolbarController:ToolbarController,
        sceneService:ISceneService,
        sceneEditorService:SceneEditorService,
        sceneViewFactory:SceneViewFactory,
        shaderPreviewRenderer:ShaderPreviewRenderer,
        viewportService:ViewportService,
        viewModules:Iterable<IViewModule>,
        shaderNodeRegistry:ShaderNodeRegistry,
        shaderHistory:ShaderHistoryService,
        saveShader:SaveShaderUseCase,
        loadShader:LoadShaderUseCase,
        languageServer:ILanguageServer,
        projectService:ProjectService,
        assetBrowserService:AssetBrowserService,
        projectTreeService:ProjectTreeService
    ) {
        this.windowService = windowService;
        this.menuService = menuService;
        this.loadProjectUseCase = loadProjectUseCase;
        this.projectService = projectService;
        this.setFullscreenUseCase = setFullscreenUseCase;
        this.openViewUseCase = openViewUseCase;
        this.viewRegistry = viewRegistry;
        this.pluginManager = pluginManager;
        this.eventBus = eventBus;
        this.fileDialog = fileDialog;
        this.fileSystem = fileSystem;
        this.platform = platform;
        this.layoutEngine = layoutEngine;
        this.menuController = menuController;
        this.windowController = windowController;
        this.toolbarController = toolbarController;
        this.sceneService = sceneService;
        this.sceneEditorService = sceneEditorService;
        this.sceneViewFactory = sceneViewFactory;
        this.shaderPreviewRenderer = shaderPreviewRenderer;
        this.viewportService = viewportService;
        this.viewModules = viewModules;
        this.shaderNodeRegistry = shaderNodeRegistry;
        this.shaderHistory = shaderHistory;
        this.saveShader = saveShader;
        this.loadShader = loadShader;
        this.languageServer = languageServer;
        this.assetBrowserService = assetBrowserService;
        this.projectTreeService = projectTreeService;
        inst = this;
        
        //views = viewRegistry.all(); 
        
        menuService.onItemClick("project.open", onMenuOpenProject);
        menuService.onItemClick("view.fullscreen", onToggleFullscreen);
        menuService.onItemClick("layout.save", onLayoutSave);
        menuService.onItemClick("project.close", onCloseProject);
        menuService.onItemClick("help.about", showAboutDialog);
        menuService.onItemClick("app.exit", function() {
            js.Browser.window.close();
        });
        /*
        for (view in viewRegistry.all()) {
            trace(view.name);
            menuService.addViewMenu(view);
            menuService.onItemClick("view." + view.name, function() openView(view.name));
        }*/
        
        // Используем js.Browser.document вместо Element.byId
        var statusEl = js.Browser.document.getElementById("status-bar");
        statusBar = new StatusBar(statusEl);


        
        _projectLoadedUnsub = eventBus.subscribe(ProjectLoaded, onProjectLoadedHandler);
        _errorUnsub = eventBus.subscribe(ErrorOccurred, onErrorOccurred);
        _layoutChangedUnsub = eventBus.subscribe(LayoutChanged, function(e:LayoutChanged) {
            trace("Layout changed");
        });
        _projectClosedUnsub = eventBus.subscribe(ProjectClosed, function(e:ProjectClosed) {
            _currentProject = null;
            statusBar.showMessage("Project closed");
            updateWindowTitle();
        });
    }
    
    public function onMenuOpenProject():Void {
        layoutEngine.open("welcome", {}, DisplayPosition.Center);
        /*
        fileDialog.showOpen({ filters: [{ name: "Project Files", extensions: ["json", "hide"] }] })
        .handle(function(path:Null<String>) {
            if (path != null) {
                var result = loadProjectUseCase.execute(new FilePath(path));
                switch (result) {
                    case Success(_):
                        trace("Project loading initiated successfully.");
                    case Failure(err):
                        statusBar.setError('Failed to load project: $err');
                }
            }
        });*/
    }
    
    private function onErrorOccurred(event:ErrorOccurred):Void {
        trace("UI ERROR [" + event.context + "]: " + event.error);
    }
    
    private function onProjectLoadedHandler(event:ProjectLoaded):Void {
        _currentProject = event.project.name;
        trace("UI: Project loaded successfully: " + _currentProject);
        updateWindowTitle();
        //openView("project");
        //openView("editor");
    }
    
    public function onToggleFullscreen():Void {
        // isFullscreen — это var, а не функция! Убираем скобки
        setFullscreenUseCase.execute(!windowService.isFullscreen);
    }
    
    public function onLayoutSave():Void {
        //saveLayoutUseCase.execute();
    }
    
    public function onCloseProject():Void {
        //closeProjectUseCase.execute();
    }
    
    private function openView(viewName:String):Void {
        // Используем Lambda.find вместо Array.find
        trace("[Open view] search view to open: "+ viewName);
        var view = Lambda.find(viewRegistry.all(), function(v) return v.name == viewName);
        if (view == null) {
            throw "View not found: " + viewName;
        }
        
        var position = switch viewName {
            case "editor": DisplayPosition.Center;
            case "project": DisplayPosition.Left;
            default: DisplayPosition.Center;
        };
        trace("[Open view] view opened");
        openViewUseCase.execute(view.name, view.defaultState, position);
    }
    
    private function onOpenRecent(path:String):Void {
        projectService.openProject(new FilePath(path));
        //loadProjectUseCase.execute(new FilePath(path));
    }
    
    private function updateWindowTitle():Void {
        var title = _currentProject != null ? '$_currentProject - HIDE IDE' : 'HIDE IDE';
        trace("Window title updated to: " + title);
        windowService.setTitle(title);
    }
    
    private function showAboutDialog():Void {
        trace('HIDE IDE\nVersion 0.1.0');
    }
    
    private function get_currentProjectName():String {
        return _currentProject != null ? _currentProject : "No project";
    }
    
    
    
    public function startup():Void {
        trace("✅ DI Контейнер успешно инициализирован! Ide создан.");

        // ✅ НОВОЕ: Регистрируем все View через модули (атомарно!)
        for (module in viewModules) {
            var descriptor = module.getDescriptor();
            viewRegistry.add(descriptor.dto);
            viewRegistry.registerViewFactory(descriptor.dto.name, descriptor.factory);
            
            // Добавляем пункт в меню
            menuService.addViewMenu(descriptor.dto);
            menuService.onItemClick("view." + descriptor.dto.name, function() {
                openView(descriptor.dto.name);
            });
            
            trace('📦 View registered: ${descriptor.dto.name}');
        }

        windowController.init();
        trace("🪟 WindowController инициализирован");

        // ✅ ИНИЦИАЛИЗАЦИЯ TOOLBAR
        var toolbarEl = js.Browser.document.getElementById("main-toolbar");
        if (toolbarEl != null) {
            // ToolbarController уже в DI, получаем его
            
            toolbarController.setContainer(cast toolbarEl);
            trace("🔧 Toolbar инициализирован");
        }
        // 1. Инициализируем GoldenLayout
        var layoutEl = js.Browser.document.getElementById("golden-layout-root");
        if (layoutEl != null) {
            layoutEngine.setContainer(layoutEl);
            // Инициализируем с пустым состоянием (адаптер сам создаст дефолтный скелет)
            layoutEngine.init({ content: [], fullScreen: null }); 
            trace("🎨 GoldenLayout инициализирован.");
        } else {
            trace("❌ Element #golden-layout-root not found in DOM! Проверьте app.html.");
        }
       
        var menuContainer = js.Browser.document.getElementById("main-menu");
        if (menuContainer != null) {
            menuController.setContainer(cast menuContainer);
            trace("📋 MenuController инициализирован с DOM-контейнером.");
        } else {
            trace("⚠️ Контейнер #main-menu не найден в DOM!");
        }

        var args = platform.getAppArgs();
        var projectFile:Null<String> = null;
        // ✅ Подписка на resize окна через js.Browser
        _resizeHandler = function(_) {
            haxe.Timer.delay(function() {
                var layoutEl = js.Browser.document.getElementById("golden-layout-root");
                if (layoutEl != null) {
                    var rect = layoutEl.getBoundingClientRect();
                    layoutEngine.updateSize(Std.int(rect.width), Std.int(rect.height));
                }
            }, 100); // Небольшая задержка для стабильности
        };

        js.Browser.window.addEventListener("resize", _resizeHandler);
        // Electron передает много внутренних флагов. Ищем первый аргумент, 
        // который НЕ начинается с '-' и не является пустой строкой.
        for (arg in args) {
            if (arg != "" && !StringTools.startsWith(arg, "-") && !StringTools.startsWith(arg, "chrome://")) {
                projectFile = arg;
                break;
            }
        }
        projectFile = 'D:\\Dev\\tetris-game-project\\tetris-game-project.hideproj';
        if (projectFile != null) {
            trace("📂 Загрузка проекта из аргумента командной строки: " + projectFile);
            projectService.openProject(new FilePath(projectFile));
            //loadProjectUseCase.execute(new FilePath(projectFile));
        } else {
            trace("👋 Приложение запущено без проекта.");

        }
    }
    
    public function dispose():Void {
        if (_projectLoadedUnsub != null) _projectLoadedUnsub.cancel();
        if (_errorUnsub != null) _errorUnsub.cancel();
        if (_layoutChangedUnsub != null) _layoutChangedUnsub.cancel();
        if (_projectClosedUnsub != null) _projectClosedUnsub.cancel();
        // ✅ Очищаем ресурсы контроллера меню
        if (menuController != null) {
            menuController.dispose();
        }
        if (windowController != null) {
            windowController.dispose();
        }
        // ✅ Отписка от resize
        if (_resizeHandler != null) {
            js.Browser.window.removeEventListener("resize", _resizeHandler);
            _resizeHandler = null;
        }
    }
    public function get_eventBus():IEventBus return eventBus;
    public function get_windowService():WindowService return windowService;
    public function get_menuService():MenuService return menuService;
    public function get_viewRegistry():ViewRegistry return viewRegistry;
    public function get_languageServer():ILanguageServer return languageServer;

    public function get_layoutEngine():ILayoutEngine return layoutEngine;
    public function get_sceneService():ISceneService return sceneService;
    public function get_shaderPreviewRenderer():ShaderPreviewRenderer return shaderPreviewRenderer;
    public function get_viewportService():ViewportService return viewportService;
    // Геттеры:
    public function get_fileSystem():IFileSystem return fileSystem;
    public function get_fileDialog():IFileDialog return fileDialog;

    public function get_shaderNodeRegistry():ShaderNodeRegistry return shaderNodeRegistry;
    public function get_shaderHistory():ShaderHistoryService return shaderHistory;
    public function get_saveShader():SaveShaderUseCase return saveShader;
    public function get_loadShader():LoadShaderUseCase return loadShader;
    public function get_assetBrowser():AssetBrowserService return assetBrowserService;
    public function get_projectTree():ProjectTreeService return projectTreeService;
    public function get_projectService():ProjectService return projectService;

}