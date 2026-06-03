package hide.presentation;

import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.presentation.ui.View;
import hide.presentation.ui.StatusBar;
import hide.shared.types.Result;
import hide.shared.types.Success;
import hide.shared.types.Failure;

import hide.application.commands.LoadProjectUseCase;
import hide.application.commands.SetFullscreenUseCase;

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

    // === Сервисы (инъекция зависимостей) ===
    private var windowService:WindowService;
    private var menuService:MenuService;
    private var loadProjectUseCase:LoadProjectUseCase;
    private var setFullscreenUseCase:SetFullscreenUseCase;
    private var saveLayoutUseCase:SaveLayoutUseCase;
    private var closeProjectUseCase:CloseProjectUseCase;

    // === UI компоненты ===
    private var statusBar:StatusBar;
    private var views:Map<String, View<Dynamic>>;

    // === Состояние (только для отображения) ===
    public var currentProjectName(get, never):String;
    private var _currentProject:Null<String>;

    // === Контейнер зависимостей ===
    private var services:ServiceContainer;

    // === Отписки от EventBus (для dispose) ===
    private var _projectLoadedUnsub:Void->Void;
    private var _errorUnsub:Void->Void;
    private var _layoutChangedUnsub:Void->Void;

    /**
     * Конструктор. Принимает уже сконфигурированный `ServiceContainer`.
     */
    public function new(_services:ServiceContainer) {
        inst = this;
        services = _services;

        // Получение сервисов
        windowService = services.get("window");
        menuService = services.get("menu");
        loadProjectUseCase = services.get("loadProject");
        setFullscreenUseCase = services.get("setFullscreen");
        saveLayoutUseCase = services.get("saveLayout");
        closeProjectUseCase = services.get("closeProject");

        // Инициализация UI
        statusBar = new StatusBar(Element.byId("status-bar"));
        views = new Map();

        // Подписка на события
        var eventBus = services.get<IEventBus>("eventBus");

        _projectLoadedUnsub = eventBus.subscribe(function(e:ProjectLoaded) {
            _currentProject = e.project.name;
            statusBar.showMessage('Project loaded: ${e.project.name}');
            updateWindowTitle();
        });

        _errorUnsub = eventBus.subscribe(function(e:ErrorOccurred) {
            statusBar.setError('${e.context}: ${e.error.message}');
        });

        _layoutChangedUnsub = eventBus.subscribe(function(e:LayoutChanged) {
            // Можно добавить "dirty indicator"
            trace("Layout changed");
        });
    }

    // === Обработчики пользовательских действий ===

    public function onMenuOpenProject():Void {
        services.get<IFileDialog>("fileDialog").showOpen({ filters: ["json"] })
            .then(function(path) {
                if (path != null) {
                    loadProjectUseCase.execute(new FilePath(path))
                        .then(function(result) {
                            switch result {
                                case Success(_): // проект загружен через ProjectLoaded
                                    null;
                                case Failure(err):
                                    statusBar.setError('Failed to load: ${err.message}');
                            }
                        });
                }
            })
            .catch(function(err) {
                statusBar.setError('File dialog error: ${err.message}');
            });
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
            // case "project.recents.*": onOpenRecent(...) // обрабатывается в MenuService
            default:
                // log unknown ID
                trace("Unknown menu item ID: $id");
        }
    }

    // === Вспомогательные методы для обновления UI ===
    private function onOpenRecent(path:String):Void {
        loadProjectUseCase.execute(new FilePath(path));
    }
    private function updateWindowTitle():Void {
        var title = _currentProject != null ? '${_currentProject} - HIDE' : 'HIDE IDE';
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
        var container = new ServiceContainer();

        // Регистрация платформы
        #if electron
        container.register("platform", new ElectronPlatform());
        #elseif nw
        container.register("platform", new NwPlatform());
        #else
        container.register("platform", new StubPlatform());
        #end

        var platform = container.get<IPlatform>("platform");

        // Регистрация сервисов
        container.register("window", new WindowService(platform.window));
        container.register("menu", new MenuService(platform.clipboard));
        container.register("eventBus", new EventBusImpl());
        container.register("dialog", new DialogImpl());
        container.register("fileDialog", new FileDialogImpl());
        container.register("appInfo", new AppInfoImpl());

        //Use-Cases
        container.register("saveLayout", new SaveLayoutUseCase(
            container.get<ILayoutEngine>("layout"),
            container.get<IEventBus>("eventBus")
        ));

        container.register("closeProject", new CloseProjectUseCase(
            container.get<ILayoutEngine>("layout"),
            container.get<IEventBus>("eventBus")
        ));

        container.register("openView", new OpenViewUseCase(
            container.get<ILayoutEngine>("layout")
        ));

        container.register("addRecentProject", new AddRecentProjectUseCase(
            container.get<MenuService>("menu"),
            container.get<IEventBus>("eventBus")
        ));

        container.register("clearRecentProjects", new ClearRecentProjectsUseCase(
            container.get<MenuService>("menu"),
            container.get<IEventBus>("eventBus")
        ));

        container.register("setRenderer", new SetRendererUseCase(
            container.get<IEventBus>("eventBus")
        ));

        // Создаём и запускаем Ide
        var ide = new Ide(container);
        ide.startup();
    }

    private function startup():Void {
        // Инициализация меню из шаблона (данные, а не nw.Menu)
        var menuTemplate = menuService.buildFromHtml(Element.byId("mainmenu").html());
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
        _projectLoadedUnsub();
        _errorUnsub();
        _layoutChangedUnsub();
        // views.clear(), statusBar.dispose(), и т.д.
    }
}