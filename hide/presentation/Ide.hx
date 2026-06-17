package hide.presentation;

import hide.presentation.controllers.ToolbarController;
import hide.presentation.controllers.WindowController;
import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.domain.services.IFileDialog;
import hide.domain.services.IPlatform;
import hide.domain.services.IAppInfo;
import hide.presentation.ui.StatusBar;
import hide.presentation.controllers.MenuController;


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

import hx.injection.Service;
import hx.injection.ServiceCollection;
import hx.injection.ServiceProvider;
import tink.core.*;

import hide.infrastructure.di.AppModule;
using tink.CoreApi;
using hx.injection.ServiceExtensions;
using Lambda;

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
    
    private var windowService:WindowService;
    private var menuService:MenuService;
    private var layoutEngine:ILayoutEngine;
    private var menuController:MenuController;
    private var loadProjectUseCase:LoadProjectUseCase;
    private var setFullscreenUseCase:SetFullscreenUseCase;
    //private var saveLayoutUseCase:SaveLayoutUseCase;
    //private var closeProjectUseCase:CloseProjectUseCase;
    //private var openViewUseCase:OpenViewUseCase;
    private var viewRegistry:ViewRegistry;
    private var pluginManager:PluginManager;
    private var eventBus:IEventBus;
    private var fileDialog:IFileDialog;
    private var platform:IPlatform;
    private var windowController:WindowController;
    private var toolbarController:ToolbarController;
    public function new(
        windowService:WindowService,
        menuService:MenuService,
        loadProjectUseCase:LoadProjectUseCase,
        setFullscreenUseCase:SetFullscreenUseCase,
        //saveLayoutUseCase:SaveLayoutUseCase,
        //closeProjectUseCase:CloseProjectUseCase,
        //openViewUseCase:OpenViewUseCase,
        viewRegistry:ViewRegistry,
        pluginManager:PluginManager,
        eventBus:IEventBus,
        fileDialog:IFileDialog,
        platform:IPlatform,
        layoutEngine:ILayoutEngine,
        menuController:MenuController,
        windowController:WindowController,
        toolbarController:ToolbarController
    ) {
        this.windowService = windowService;
        this.menuService = menuService;
        this.loadProjectUseCase = loadProjectUseCase;
        this.setFullscreenUseCase = setFullscreenUseCase;
        //this.saveLayoutUseCase = saveLayoutUseCase;
        //this.closeProjectUseCase = closeProjectUseCase;
        //this.openViewUseCase = openViewUseCase;
        this.viewRegistry = viewRegistry;
        this.pluginManager = pluginManager;
        this.eventBus = eventBus;
        this.fileDialog = fileDialog;
        this.platform = platform;
        this.layoutEngine = layoutEngine;
        this.menuController = menuController;
        this.windowController = windowController;
        this.toolbarController = toolbarController;
        inst = this;
        views = viewRegistry.all(); 
        
        menuService.onItemClick("project.open", onMenuOpenProject);
        menuService.onItemClick("view.fullscreen", onToggleFullscreen);
        menuService.onItemClick("layout.save", onLayoutSave);
        menuService.onItemClick("project.close", onCloseProject);
        menuService.onItemClick("help.about", showAboutDialog);
        menuService.onItemClick("app.exit", function() {
            js.Browser.window.close();
        });
        for (view in viewRegistry.all()) {
            trace(view.name);
            menuService.addViewMenu(view);
            menuService.onItemClick("view." + view.name, function() openView(view.name));
        }
        
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
        var view = Lambda.find(views, function(v) return v.name == viewName);
        if (view == null) {
            throw "View not found: " + viewName;
        }
        
        var position = switch viewName {
            case "editor": DisplayPosition.Center;
            case "project": DisplayPosition.Left;
            default: DisplayPosition.Center;
        };
        
        //openViewUseCase.execute(view.name, view.defaultState, position);
    }
    
    private function onOpenRecent(path:String):Void {
        loadProjectUseCase.execute(new FilePath(path));
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
    
    public static function main():Void {
        var collection = new ServiceCollection();
        // Импортируем AppModule явно
        hide.infrastructure.di.AppModule.configure(collection);
        
        var provider = collection.createProvider();
        var ide = provider.getService(Ide);
        ide.startup();
        
        provider.getService(PluginManager).loadAll();
    }
    
    private function startup():Void {
        trace("✅ DI Контейнер успешно инициализирован! Ide создан.");
         // 2. Регистрируем временные заглушки для View (позже заменим на плагины)
            // ✅ РЕГИСТРАЦИЯ ЗАГЛУШЕК ФАБРИК
            // ✅ РЕГИСТРАЦИЯ UNITY-LIKE VIEW
        viewRegistry.registerViewFactory("scene", new hide.infrastructure.external.StubSceneFactory());
        viewRegistry.registerViewFactory("game", new hide.infrastructure.external.StubGameFactory());
        //viewRegistry.registerViewFactory("hierarchy", new hide.infrastructure.external.StubHierarchyFactory());
        //viewRegistry.registerViewFactory("inspector", new hide.infrastructure.external.StubInspectorFactory());
        viewRegistry.registerViewFactory("project", new hide.infrastructure.external.StubProjectFactory());
        
        viewRegistry.registerViewFactory("editor", new hide.infrastructure.external.StubEditorFactory());
        viewRegistry.registerViewFactory("console", new hide.infrastructure.external.StubConsoleFactory());
        viewRegistry.registerViewFactory("properties", new hide.infrastructure.external.StubPropertiesFactory());
        // ✅ РЕГИСТРАЦИЯ REACT-ФАБРИК

        // ✅ РЕГИСТРАЦИЯ INSPECTOR
        viewRegistry.registerViewFactory(
            "inspector",
            new hide.infrastructure.ui.ReactViewFactory()
                .withComponent(hide.presentation.ui.react.components.InspectorPanel)
        );
        viewRegistry.registerViewFactory(
            "hierarchy",
            new hide.infrastructure.ui.ReactViewFactory()
                .withComponent(hide.presentation.ui.react.components.HierarchyPanel)
        );
        viewRegistry.registerViewFactory(
            "welcome",
            new hide.infrastructure.ui.ReactViewFactory()
                .withComponent(hide.presentation.ui.react.components.WelcomePanel)
        );

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
        
        if (projectFile != null) {
            trace("📂 Загрузка проекта из аргумента командной строки: " + projectFile);
            loadProjectUseCase.execute(new FilePath(projectFile));
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
    public function get_layoutEngine():ILayoutEngine return layoutEngine;
}