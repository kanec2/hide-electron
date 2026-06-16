package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ProjectLoaded;
import hide.shared.events.RecentProjectsUpdated;

typedef WelcomeProps = {
    var initialState:Dynamic;
    var onUnmount:Void->Void;
}

typedef WelcomeState = {
    var currentProject:Null<String>;
    var recentProjects:Array<String>;
}

/**
 * Приветственная панель с информацией о проекте.
 * Демонстрирует интеграцию с EventBus.
 */
class WelcomePanel extends BaseReactComponent<WelcomeProps, WelcomeState> {
    
    public function new() {
        super();
        state = {
            currentProject: null,
            recentProjects: []
        };
    }
    
    override function componentDidMount():Void {
        var eventBus = UseService.eventBus();
        
        // Подписываемся на загрузку проекта
        subscribe(eventBus, ProjectLoaded, function(e:ProjectLoaded) {
            setState(function(oldState) {
                return {
                    currentProject: e.project.name,
                    recentProjects: oldState.recentProjects // Сохраняем остальные поля
                };
            });
        });
        
        // Подписываемся на обновление списка недавних проектов
        subscribe(eventBus, RecentProjectsUpdated, function(e:RecentProjectsUpdated) {
            setState(function(oldState) {
                return {
                    currentProject: oldState.currentProject,
                    recentProjects: e.recentProjects
                };
            });
        });
    }
    
    override function render():ReactElement {
        // ✅ ИСПРАВЛЕНО: выносим логику в переменные типа ReactElement
        // Обратите внимание: внутри jsx('...') используется {state.currentProject}, а не ${state.currentProject}
        var projectInfo:ReactElement = if (state.currentProject != null) {
            jsx('<div className="project-info">📂 Открыт проект: <b>{state.currentProject}</b></div>');
        } else {
            jsx('<div className="no-project">Проект не открыт. Используйте File → Open Project</div>');
        };
        
        var recentList:ReactElement = if (state.recentProjects.length > 0) {
            // Генерируем массив JSX-элементов
            var items = [for (p in state.recentProjects) jsx('<li key="{p}">{p}</li>')];
            jsx('
                <div className="recent-projects">
                    <h3>Недавние проекты:</h3>
                    <ul>{items}</ul>
                </div>
            ');
        } else {
            jsx('<div className="no-recent">Нет недавних проектов</div>');
        };
        
        // ✅ ИСПРАВЛЕНО: style теперь передаётся как анонимный объект через {{ }}
        return jsx('
            <div className="welcome-panel" style={{padding: "20px", color: "#ccc"}}>
                <h1>👋 Добро пожаловать в HIDE IDE</h1>
                {projectInfo}
                {recentList}
                <div className="hint" style={{marginTop: "20px", opacity: 0.7}}>
                    Используйте меню View для открытия панелей
                </div>
            </div>
        ');
    }
}