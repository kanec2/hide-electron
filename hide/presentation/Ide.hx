package hide.presentation;

import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.application.services.PluginManager;
import hide.application.services.ViewRegistry;
import hide.domain.services.IFileDialog;
import hide.domain.services.IPlatform;
import hide.domain.services.IAppInfo;
import hide.presentation.ui.StatusBar;
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
        layoutEngine:ILayoutEngine
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
        inst = this;
        views = viewRegistry.all(); 
        
        for (view in viewRegistry.all()) {
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
        });
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
    
    public function onMenuItemClick(id:String):Void {
        switch id {
            case "project.open": onMenuOpenProject();
            case "view.fullscreen": onToggleFullscreen();
            case "layout.save": onLayoutSave();
            case "project.close": onCloseProject();
            case "help.about": showAboutDialog();
            case "view.editor": openView("editor");
            case "view.project": openView("project");
            default:
                // Pattern matching со строковой интерполяцией не работает в Haxe!
                // Используем startsWith
                if (StringTools.startsWith(id, "project.recents.")) {
                    var path = id.substr("project.recents.".length);
                    onOpenRecent(path);
                } else {
                    trace("Unknown menu item ID: " + id);
                }
        }
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
        viewRegistry.registerViewFactory("project", new hide.infrastructure.external.StubProjectFactory());
        viewRegistry.registerViewFactory("editor", new hide.infrastructure.external.StubEditorFactory());
        viewRegistry.registerViewFactory("console", new hide.infrastructure.external.StubConsoleFactory());
        viewRegistry.registerViewFactory("properties", new hide.infrastructure.external.StubPropertiesFactory());

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
       
    
        var args = platform.getAppArgs();
        var projectFile:Null<String> = null;
        
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
    }
}