package hide.presentation;

import hide.application.commands.LoadProjectCommand;
import hide.application.commands.SetFullscreenCommand;
import hide.application.services.MenuService;
import hide.application.services.WindowService;
import hide.presentation.ui.View;
import hide.presentation.ui.StatusBar;
import hide.shared.utils.Result;

/**
 * Главный контроллер приложения.
 * ОТВЕТСТВЕННОСТЬ:
 * - Инициализация зависимостей (через контейнер)
 * - Обработка пользовательских действий → вызов Use-Cases
 * - Подписка на события → обновление UI
 * - НЕ содержит бизнес-логики!
 */
@:expose
class Ide {
    public static var inst(default, null):Ide;
    
    // Сервисы (инъекция зависимостей)
    private var windowService:WindowService;
    private var menuService:MenuService;
    private var loadProjectUseCase:LoadProjectUseCase;
    private var setFullscreenUseCase:SetFullscreenUseCase;
    
    // UI компоненты
    private var statusBar:StatusBar;
    private var views:Map<String, View<Dynamic>>;
    
    // Состояние (только для отображения, не для логики)
    public var currentProjectName(get, never):String;
    private var _currentProject:Null<String>;
    
    public function new(services:ServiceContainer) {
        inst = this;
        
        // Получение сервисов из контейнера
        windowService = services.get("window");
        menuService = services.get("menu");
        loadProjectUseCase = services.get("loadProject");
        setFullscreenUseCase = services.get("setFullscreen");
        
        // Инициализация UI
        statusBar = new StatusBar(Element.byId("status-bar"));
        views = new Map();
        
        // Подписка на события
        services.get<IEventBus>("eventBus").subscribe(function(e:ProjectLoaded) {
            _currentProject = e.project.name;
            statusBar.showMessage('Project loaded: ${e.project.name}');
            updateWindowTitle();
        });
        
        services.get<IEventBus>("eventBus").subscribe(function(e:ErrorOccurred) {
            statusBar.setError('${e.context}: ${e.error.message}');
        });
    }
    
    // === Обработчики пользовательских действий ===
    
    public function onMenuOpenProject():Void {
        // Показываем диалог выбора файла (через инфраструктуру)
        services.get<IFileDialog>("fileDialog").showOpen({ filters: ["json"] })
            .then(function(path) {
                if (path != null) {
                    // Вызываем Use-Case (бизнес-логика)
                    loadProjectUseCase.execute(new FilePath(path))
                        .then(function(result) {
                            switch result {
                                case Success(_): /* UI уже обновился через событие */
                                case Failure(err): statusBar.setError('Failed to load: ${err.message}');
                            }
                        });
                }
            });
    }
    
    public function onToggleFullscreen():Void {
        // Просто делегируем в Use-Case
        setFullscreenUseCase.execute(!windowService.isFullscreen());
    }
    
    public function onMenuItemClick(id:String):Void {
        // Маппинг ID меню на действия
        switch id {
            case "project.open": onMenuOpenProject();
            case "view.fullscreen": onToggleFullscreen();
            case "help.about": showAboutDialog();
            // ...
        }
    }
    
    // === Вспомогательные методы для обновления UI ===
    
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
        return _currentProject ?? "No project";
    }
    
    // === Точка входа ===
    
    public static function main():Void {
        // 1. Создаём контейнер зависимостей
        var container = new ServiceContainer();
        
        // 2. Регистрируем инфраструктуру (платформа)
        #if electron
        container.register("platform", new ElectronPlatform());
        #elseif nw
        container.register("platform", new NwPlatform());
        #end
        
        // 3. Регистрируем сервисы приложения
        container.register("window", new WindowService(container.get("platform").window));
        container.register("menu", new MenuService(container.get("platform").clipboard));
        container.register("loadProject", new LoadProjectUseCase(
            container.get("platform").fileSystem,
            container.get("platform").resourceLoader,
            container.get("eventBus")
        ));
        // ... остальные сервисы
        
        // 4. Создаём и запускаем Ide
        var ide = new Ide(container);
        ide.startup();
    }
    
    private function startup():Void {
        // Инициализация меню из шаблона (данные, а не nw.Menu)
        var menuTemplate = menuService.buildFromHtml(Element.byId("mainmenu").html());
        // ... рендеринг меню через UI-компоненты
        
        // Загрузка проекта из аргументов командной строки
        var args = services.get<IPlatform>("platform").getAppArgs();
        if (args.length > 0) {
            loadProjectUseCase.execute(new FilePath(args[0]));
        }
        
        // Показ окна
        windowService.show();
    }
}