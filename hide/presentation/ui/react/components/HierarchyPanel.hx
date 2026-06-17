package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;

typedef HierarchyProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef HierarchyState = {
    var objects: Array<Dynamic>;
    var selectedId: Null<String>;
}

class HierarchyPanel extends BaseReactComponent<HierarchyProps, HierarchyState> {
    public function new() {
        super();
        state = {
            objects: [
                {
                    id: "scene",
                    name: "SampleScene",
                    icon: "🎬",
                    expanded: true,
                    children: [
                        { id: "camera", name: "Main Camera", icon: "📷", children: [] },
                        { id: "light", name: "Directional Light", icon: "💡", children: [] },
                        { 
                            id: "player", 
                            name: "Player", 
                            icon: "",
                            children: [
                                { id: "mesh", name: "MeshRenderer", icon: "🎨", children: [] },
                                { id: "rigidbody", name: "Rigidbody", icon: "⚙️", children: [] }
                            ]
                        },
                        { id: "ground", name: "Ground", icon: "", children: [] }
                    ]
                }
            ],
            selectedId: "player"
        };
    }

    override function render(): ReactElement {
        return jsx('
            <div style={{padding: "10px", color: "#d4d4d4", background: "#383838", height: "100%", fontFamily: "sans-serif", fontSize: "13px"}}>
                <div style={{padding: "4px 8px", background: "#2a2a2a", borderRadius: "3px", marginBottom: "8px"}}>
                    🔍 <input type="text" placeholder="Search..." style={{background: "transparent", border: "none", color: "#fff", outline: "none", width: "80%"}} />
                </div>
                <div>
                    {[for (obj in state.objects) renderObject(obj, 0)]}
                </div>
            </div>
        ');
    }

    private function renderObject(obj: Dynamic, depth: Int): ReactElement {
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

        // ✅ ИСПРАВЛЕНО: выносим children в переменную с явной типизацией
        var childrenList: ReactElement = if (obj.expanded && hasChildren) {
            var children: Array<Dynamic> = cast obj.children;
            jsx('
                <div>
                    {[for (child in children) renderObject(child, depth + 1)]}
                </div>
            ');
        } else {
            jsx('<div></div>');
        };

        // ✅ ИСПРАВЛЕНО: используем bind вместо => лямбды
        return jsx('
            <div key={obj.id}>
                <div 
                    style={rowStyle}
                    onClick={handleSelect.bind(obj.id)}>
                    {hasChildren ? (obj.expanded ? "▼ " : "▶ ") : "  "}
                    {obj.icon} {obj.name}
                </div>
                {childrenList}
            </div>
        ');
    }

    private function handleSelect(id: String): Void {
        setState({
            selectedId: id,
            objects: state.objects
        });
        // TODO: Опубликовать событие ObjectSelected через EventBus
    }
}