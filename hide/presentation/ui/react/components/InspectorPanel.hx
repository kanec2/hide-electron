package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;

typedef InspectorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef InspectorState = {
    var selectedObject: Null<Dynamic>;
    var components: Array<Dynamic>;
}

class InspectorPanel extends BaseReactComponent<InspectorProps, InspectorState> {
    public function new() {
        super();
        state = {
            selectedObject: null,
            components: []
        };
    }

    override function componentDidMount(): Void {
        var transformFields: Array<Dynamic> = [
            { label: "Position", x: 0, y: 1.5, z: 0 },
            { label: "Rotation", x: 0, y: 0, z: 0 },
            { label: "Scale", x: 1, y: 1, z: 1 }
        ];
        
        var meshRendererFields: Array<Dynamic> = [
            { label: "Mesh", value: "Player.mesh" },
            { label: "Material", value: "Default-Diffuse" }
        ];
        
        var rigidbodyFields: Array<Dynamic> = [
            { label: "Mass", value: 1 },
            { label: "Gravity", value: true, type: "checkbox" }
        ];
        
        var componentsData: Array<Dynamic> = [
            {
                name: "Transform",
                fields: transformFields
            },
            {
                name: "Mesh Renderer",
                fields: meshRendererFields
            },
            {
                name: "Rigidbody",
                fields: rigidbodyFields
            }
        ];
        
        setState({
            selectedObject: { name: "Player", tag: "Player" },
            components: componentsData
        });
    }

    override function render(): ReactElement {
        var header: ReactElement = if (state.selectedObject != null) {
            jsx('
                <div style={{padding: "8px", background: "#2a2a2a", borderRadius: "3px", marginBottom: "8px"}}>
                    <div style={{display: "flex", alignItems: "center", gap: "8px"}}>
                        <input type="checkbox" defaultChecked={true} />
                        <b style={{color: "#fff"}}> {state.selectedObject.name}</b>
                        <span style={{marginLeft: "auto", color: "#888", fontSize: "11px"}}>
                            Tag: {state.selectedObject.tag}
                        </span>
                    </div>
                </div>
            ');
        } else {
            jsx('<div style={{padding: "20px", textAlign: "center", color: "#888"}}>No object selected</div>');
        };

        var componentsList: ReactElement = jsx('
            <div style={{overflowY: "auto", maxHeight: "calc(100% - 60px)"}}>
                {[for (comp in state.components) renderComponent(comp)]}
                <div style={{marginTop: "10px", textAlign: "center"}}>
                    <button style={{background: "#4a4a4a", color: "#fff", border: "1px solid #555", padding: "4px 12px", borderRadius: "3px", cursor: "pointer"}}>
                        Add Component
                    </button>
                </div>
            </div>
        ');

        return jsx('
            <div style={{padding: "10px", color: "#d4d4d4", background: "#383838", height: "100%", fontFamily: "sans-serif", fontSize: "13px"}}>
                {header}
                {componentsList}
            </div>
        ');
    }

    private function renderComponent(comp: Dynamic): ReactElement {
        // ✅ ИСПРАВЛЕНО: явная типизация fields
        var fields: Array<Dynamic> = cast comp.fields;
        
        return jsx('
            <div key={comp.name} style={{background: "#2a2a2a", borderRadius: "3px", marginBottom: "6px"}}>
                <div style={{padding: "6px 8px", background: "#3a3a3a", fontWeight: "bold", borderBottom: "1px solid #222"}}>
                    🔽 {comp.name}
                </div>
                <div style={{padding: "8px"}}>
                    {[for (field in fields) renderField(field)]}
                </div>
            </div>
        ');
    }

    private function renderField(field: Dynamic): ReactElement {
        var type = field.type != null ? field.type : "input";
        
        return switch (type) {
            case "checkbox":
                jsx('
                    <div style={{display: "flex", gap: "4px", marginBottom: "4px"}}>
                        <span style={{width: "60px", color: "#aaa"}}>{field.label}</span>
                        <input type="checkbox" defaultChecked={field.value} />
                    </div>
                ');
            case "vector3":
                jsx('
                    <div style={{display: "flex", gap: "4px", marginBottom: "4px"}}>
                        <span style={{width: "60px", color: "#aaa"}}>{field.label}</span>
                        <input defaultValue={field.x} style={{flex: 1, background: "#1a1a1a", border: "1px solid #555", color: "#fff", padding: "2px 4px", borderRadius: "2px"}} />
                        <input defaultValue={field.y} style={{flex: 1, background: "#1a1a1a", border: "1px solid #555", color: "#fff", padding: "2px 4px", borderRadius: "2px"}} />
                        <input defaultValue={field.z} style={{flex: 1, background: "#1a1a1a", border: "1px solid #555", color: "#fff", padding: "2px 4px", borderRadius: "2px"}} />
                    </div>
                ');
            default:
                jsx('
                    <div style={{display: "flex", gap: "4px", marginBottom: "4px"}}>
                        <span style={{width: "60px", color: "#aaa"}}>{field.label}</span>
                        <input defaultValue={field.value} style={{flex: 1, background: "#1a1a1a", border: "1px solid #555", color: "#fff", padding: "2px 4px", borderRadius: "2px"}} />
                    </div>
                ');
        };
    }
}