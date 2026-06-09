package hide.presentation;

import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.application.services.PluginManager;
import hide.presentation.ui.View;
import hide.presentation.ui.StatusBar;
import hide.shared.types.Result;
import hide.shared.types.Success;
import hide.shared.types.Failure;

import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;
import hide.application.dto.ViewDto;
import hide.domain.valueobjects.DisplayPosition;
// Импорты для событий
import hide.shared.events.ProjectLoaded;
import hide.shared.events.ErrorOccurred;
import hide.shared.events.LayoutChanged;
import hide.shared.events.ProjectClosed;

// Импорты для типов
import hide.shared.types.FilePath;
import hide.shared.types.IFileDialog;
import hide.shared.types.IEventBus;
import hide.shared.types.IDialog;
import hide.shared.types.IAppInfo;
import hide.shared.types.IPlatform;

import hx.injection.ServiceCollection;
import hx.injection.ServiceProvider;

// ✅ Включаем extension-методы для красивого синтаксиса
using hx.injection.ServiceExtensions;
/**
 * Главный контроллер приложения (Presentation Layer).
 * ОТВЕТСТВЕННОСТЬ:
 * - Инициализация зависимостей (через контейнер)
 * - Обработка пользовательских действий → вызов Use-Cases
 * - Подписка на события → обновление UI
 * - НЕ содержит бизнес-логики!
 */
@:expose
class Ide {
    public static var inst(default, null):Ide;


    private var views:Array<ViewDto>;
    // === UI компоненты ===
    private var statusBar:StatusBar;

    // === Состояние (только для отображения) ===
    public var currentProjectName(get, never):String;
    private var _currentProject:Null<String>;

    // === Контейнер зависимостей ===
    private var services:ServiceContainer;

    // === Отписки от EventBus (для dispose) ===
    private var _projectLoadedUnsub:CallbackLink;
    private var _errorUnsub:CallbackLink;
    private var _layoutChangedUnsub:CallbackLink;

    // === Сервисы ===
    private var windowService:WindowService,
    private var menuService:MenuService,
    private var loadProjectUseCase:LoadProjectUseCase,
    private var setFullscreenUseCase:SetFullscreenUseCase,
    private var saveLayoutUseCase:SaveLayoutUseCase,
    private var closeProjectUseCase:CloseProjectUseCase,
    private var openViewUseCase:OpenViewUseCase,
    private var viewRegistry:ViewRegistry,
    private var pluginManager:PluginManager,
    private var eventBus:IEventBus // Для подписок

    /**
     * Конструктор. Принимает уже сконфигурированный `ServiceContainer`.
     */
    public function new(
        windowService:WindowService,
        menuService:MenuService,
        loadProjectUseCase:LoadProjectUseCase,
        setFullscreenUseCase:SetFullscreenUseCase,
        saveLayoutUseCase:SaveLayoutUseCase,
        closeProjectUseCase:CloseProjectUseCase,
        openViewUseCase:OpenViewUseCase,
        viewRegistry:ViewRegistry,
        pluginManager:PluginManager,
        eventBus:IEventBus // Для подписок
    ) {
        this.windowService = windowService
        this.menuService = menuService
        this.loadProjectUseCase = loadProjectUseCase
        this.setFullscreenUseCase = setFullscreenUseCase
        this.saveLayoutUseCase = saveLayoutUseCase
        this.closeProjectUseCase = closeProjectUseCase
        this.openViewUseCase = openViewUseCase
        this.viewRegistry = viewRegistry
        this.pluginManager = pluginManager
        this.eventBus = eventBus
        inst = this;

        // Добавить обработчики для view через MenuService
        for (view in viewRegistry.all();) {
            menuService.addViewMenu(view);
            menuService.onItemClick("view.${view.name}", function() openView(view.name));
        }


        // Инициализация UI
        statusBar = new StatusBar(Element.byId("status-bar"));
        views = new Map();

        // Подписка на события
        _projectLoadedUnsub = eventBus.subscribe(ProjectLoaded,onProjectLoadedHandler);
        
        _errorUnsub = eventBus.subscribe(ErrorOccurred, function(e:ErrorOccurred) {
            statusBar.setError('${e.context}: ${e.error.message}');
        });

        _layoutChangedUnsub = eventBus.subscribe(LayoutChanged, function(e:LayoutChanged) {
            // Можно добавить "dirty indicator"
            trace("Layout changed");
        });

        _projectClosedUnsub = eventBus.subscribe(ProjectClosed, function(e:ProjectClosed) {
            _currentProject = null;
            statusBar.showMessage("Project closed");
            updateWindowTitle();
        });
    }

    // === Обработчики пользовательских действий ===
    public function onMenuOpenProject(): Void {
        // 1. Показываем диалог выбора файла (предполагаем, что IFileDialog зарегистрирован в DI)
        var fileDialog = services.get("fileDialog"); 
        
        fileDialog.showOpen({ filters: ["json", "hide"] }).then(function(path: String) {
            if (path != null) {
                // 2. Вызываем UseCase
                var result = loadProjectUseCase.execute(new FilePath(path));
                
                // 3. Обрабатываем результат (хотя основное обновление UI произойдет через EventBus)
                switch (result) {
                    case Success(_):
                        trace("Project loading initiated successfully.");
                    case Failure(err):
                        statusBar.setError('Failed to load project: $err');
                }
            }
        }).catch(function(err: Dynamic) {
            statusBar.setError('File dialog error: ${Std.string(err)}');
        });
    }

    // Этот метод вызывается автоматически, когда UseCase публикует ProjectLoaded
    private function onProjectLoadedHandler(event: ProjectLoaded): Void {
        _currentProject = event.project.name;
        statusBar.showMessage('Project loaded: ${_currentProject}');
        updateWindowTitle();
        
        // БОНУС: Автоматически открываем нужные вьюхи при загрузке проекта
        openView("project"); // Открыть дерево проекта слева
        openView("editor");  // Открыть редактор по центру
    }

    public function onToggleFullscreen():Void {
        setFullscreenUseCase.execute(!windowService.isFullscreen());
    }

    public function onLayoutSave():Void {
        saveLayoutUseCase.execute();
    }

    public function onCloseProject():Void {
        closeProjectUseCase.execute();
    }

    public function onMenuItemClick(id:String):Void {
        switch id {
            case "project.open": onMenuOpenProject();
            case "view.fullscreen": onToggleFullscreen();
            case "layout.save": onLayoutSave();
            case "project.close": onCloseProject();
            case "help.about": showAboutDialog();
            case "project.recents.${p}": onOpenRecent(p);
            case "view.editor": openView("editor"); // ← ДОБАВИТЬ
            case "view.project": openView("project"); // ← ДОБАВИТЬ
            // case "project.recents.*": onOpenRecent(...) // обрабатывается в MenuService
            default:
                // log unknown ID
                trace("Unknown menu item ID: $id");
        }
    }
    // — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — —
    // 🔧 ДОБАВИТЬ:
    private function openView(viewName:String):Void {
        var view = views.find(v -> v.name == viewName);
        if (view == null) {
            throw "View not found: $viewName";
        }

        var position = switch viewName {
            case "editor": DisplayPosition.Center;
            case "project": DisplayPosition.Left;
            default: DisplayPosition.Center;
        };

        openViewUseCase.execute(view.name, view.defaultState, position);
    }
    
    // === Вспомогательные методы для обновления UI ===
    private function onOpenRecent(path:String):Void {
        loadProjectUseCase.execute(new FilePath(path));
    }

    private function updateWindowTitle(): Void {
        var title = _currentProject != null ? '$_currentProject - HIDE IDE' : 'HIDE IDE';
        windowService.setTitle(title);
    }

    private function showAboutDialog():Void {
        services.get<IDialog>("dialog").showInfo('HIDE IDE\nVersion ${getAppVersion()}');
    }

    private function getAppVersion():String {
        return services.get<IAppInfo>("appInfo").version;
    }

    // === Геттеры ===

    private function get_currentProjectName():String {
        return _currentProject != null ? _currentProject : "No project";
    }

    // === Точка входа ===

    public static function main():Void {
        // 1. Создаем пустую коллекцию
        var collection = new ServiceCollection();

        // 2. Делегируем конфигурацию специализированному классу
        AppModule.configure(collection);

        // 3. Создаем провайдер (он строит граф зависимостей)
        var provider = collection.createProvider();

        // 4. Запрашиваем главный класс. Все его зависимости будут разрешены автоматически!
        var ide = provider.getService(Ide);
        
        // 5. Запускаем
        ide.startup();

        // 6. Инициализируем плагины
        provider.getService(PluginManager).loadAll();
    }

    private function startup():Void {
        // Инициализация меню из шаблона (данные, а не nw.Menu)
        //var menuTemplate = menuService.buildFromHtml(Element.byId("mainmenu").html());
        // Регистрация обработчиков кликов (в UI-рендере или здесь)
        // menuService.onItemClick("project.recents.${p}", onOpenRecent)

        // Загрузка проекта из аргументов командной строки
        var args = services.get<IPlatform>("platform").getAppArgs();
        if (args.length > 0) {
            loadProjectUseCase.execute(new FilePath(args[0]));
        }

        // Показ окна
        windowService.show();
    }

    // === Ресурсоосвобождение (для dispose) ===
    public function dispose():Void {
        if (_projectLoadedLink != null) _projectLoadedLink.cancel();
        if (_errorLink != null) _errorLink.cancel();
        _projectLoadedUnsub();
        _errorUnsub();
        _layoutChangedUnsub();
        _projectClosedUnsub();
        // views.clear(), statusBar.dispose(), и т.д.
    }
}