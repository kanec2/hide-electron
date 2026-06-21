package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ObjectSelected;
import hide.engine.domain.entities.SceneObject;

typedef HierarchyProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef HierarchyState = {
    var root: Null<SceneObject>;
    var selectedId: Null<String>;
}

class HierarchyPanel extends BaseReactComponent<HierarchyProps, HierarchyState> {
    public function new() {
        super();
        state = { root: null, selectedId: null };
    }

    override function componentDidMount(): Void {
        var scene = UseService.sceneService();
        var eventBus = UseService.eventBus();

        // 1. Загружаем реальное дерево сцены
        setState({ root: scene.getRoot(), selectedId: null });

        // 2. Подписываемся на изменения сцены (добавление/удаление объектов)
        subscribe(eventBus, hide.shared.events.ObjectChanged, function(_) {
            setState({ root: scene.getRoot(), selectedId: state.selectedId });
        });

        // 3. Подписываемся на внешний выбор (например, кликом в 3D-вью)
        subscribe(eventBus, ObjectSelected, function(e:ObjectSelected) {
            trace('🖥️ [Hierarchy] Received ObjectSelected: ${e.objectId}');
            setState({ root: state.root, selectedId: e.objectId });
        });
    }

    override function render(): ReactElement {
        if (state.root == null) {
            return jsx('<div style={{padding:"10px",color:"#888"}}>No scene loaded</div>');
        }

        return jsx('
            <div style={{padding:"10px",color:"#d4d4d4",background:"#383838",height:"100%",fontFamily:"sans-serif",fontSize:"13px"}}>
                {renderObject(state.root, 0)}
            </div>
        ');
    }

    private function renderObject(obj: SceneObject, depth: Int): ReactElement {
        var isSelected = state.selectedId == obj.id;
        var hasChildren = obj.children != null && obj.children.length > 0;
        var paddingLeft = depth * 16;

        var rowStyle = {
            padding: "3px 8px",
            paddingLeft: (paddingLeft + 8) + "px",
            cursor: "pointer",
            borderRadius: "3px",
            background: isSelected ? "#2d5c8a" : "transparent"
        };

        var childrenList: ReactElement = if (hasChildren) {
            jsx('<div>{[for (child in obj.children) renderObject(child, depth + 1)]}</div>');
        } else {
            jsx('<div></div>');
        };

        return jsx('
            <div key={obj.id}>
                <div
                    style={rowStyle}
                    onClick={handleSelect.bind(obj.id)}>
                    {hasChildren ? "▼ " : "  "}🎭 {obj.name}
                </div>
                {childrenList}
            </div>
        ');
    }

    

    private function handleSelect(id: String): Void {
        // ✅ ЧИСТО: просто вызываем метод движка.
        // Движок сам опубликует ObjectSelected через IEngineEventBus →
        // SceneEditorService → IDE EventBus → наша подписка выше обновит UI.
        trace('🎯 [Hierarchy] Selecting object: $id');
        UseService.sceneService().select(id);
    }
}