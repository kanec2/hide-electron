package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;

typedef NodePropertiesProps = {
    var selectedNode: Dynamic; // LGraphNode
    var onPropertyChange: Void->Void; // ← НОВОЕ
}

typedef NodePropertiesState = {
    var selectedNode: Dynamic;
    var properties: Dynamic;
}

class NodePropertiesPanel extends BaseReactComponent<NodePropertiesProps, NodePropertiesState> {
    public function new() {
        super();
        state = {
            selectedNode: null,
            properties: null
        };
    }

    override function render(): ReactElement {
        // ✅ ИСПРАВЛЕНО: используем props.selectedNode, а не state
        if (props.selectedNode == null) {
            return jsx('
                <div style={{color: "#888", fontSize: "12px", padding: "10px"}}>
                    Select a node to edit properties
                </div>
            ');
        }

        return jsx('
            <div style={{padding: "10px"}}>
                <h4 style={{margin: "0 0 10px 0", color: "#fff"}}>
                    {props.selectedNode.title}
                </h4>
                {renderProperties()}
            </div>
        ');
    }

    private function renderProperties(): ReactElement {
        var props = props.selectedNode.properties;
        if (props == null) {
            return jsx('<div style={{color: "#666"}}>No properties</div>');
        }

        var fields: Array<ReactElement> = [];
        for (key in Reflect.fields(props)) {
            var value = Reflect.field(props, key);
            fields.push(renderPropertyField(key, value));
        }

        return jsx('<div>{fields}</div>');
    }

    private function renderPropertyField(key: String, value: Dynamic): ReactElement {
        // ✅ ИСПРАВЛЕНО: приводим value к Dynamic для defaultValue
        var defaultValue: Dynamic = value;
        return jsx('
            <div key={key} style={{marginBottom: "8px"}}>
                <label style={{display: "block", color: "#aaa", fontSize: "11px", marginBottom: "4px"}}>
                    {key}
                </label>
                <input 
                    type="text"
                    defaultValue={Std.string(value)}
                    onChange={function(e) handlePropertyChange(key, e.target.value)}
                    style={{
                        width: "100%",
                        padding: "4px 8px",
                        background: "#1a1a1a",
                        border: "1px solid #444",
                        borderRadius: "3px",
                        color: "#fff",
                        boxSizing: "border-box"
                    }}
                />
            </div>
        ');
    }
/*
    private function handlePropertyChange(key: String, value: String): Void {
        if (state.selectedNode != null) {
            // Конвертируем строку в нужный тип
            var parsed: Dynamic = value;
            // Пробуем распарсить как число
            var floatVal = Std.parseFloat(value);
            if (!Math.isNaN(floatVal)) {
                parsed = floatVal;
            }
            
            //state.selectedNode.properties[key] = parsed;
            Reflect.setProperty(state.selectedNode.properties, key, parsed);
            state.selectedNode.setDirtyCanvas(true, true);
            
            trace('🔄 Property changed: $key = $parsed');
        }
    }
*/
    private function handlePropertyChange(key: String, value: String): Void {
        if (props.selectedNode != null) {
            var parsed: Dynamic = value;
            var floatVal = Std.parseFloat(value);
            if (!Math.isNaN(floatVal)) {
                parsed = floatVal;
            }
            
            Reflect.setProperty(props.selectedNode.properties, key, parsed);
            props.selectedNode.setDirtyCanvas(true, true);
            
            // ✅ УВЕДОМЛЯЕМ PARENT ОБ ИЗМЕНЕНИИ
            if (props.onPropertyChange != null) {
                props.onPropertyChange();
            }
        }
    }
}