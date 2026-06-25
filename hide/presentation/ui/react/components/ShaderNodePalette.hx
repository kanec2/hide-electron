package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;

typedef ShaderNodePaletteProps = {
    var onNodeDragStart: String->Void;
}

typedef NodeCategory = {
    var name: String;
    var nodes: Array<NodeInfo>;
}

typedef NodeInfo = {
    var type: String;        // "math/add", "texture/sample" и т.д.
    var label: String;       // "Add", "Texture Sample"
    var description: String;
    var color: String;       // цвет для иконки
}

class ShaderNodePalette extends ReactComponentOfProps<ShaderNodePaletteProps> {
    
    private function getCategories(): Array<NodeCategory> {
        return [
            {
                name: "Input/Output",
                nodes: [
                    { type: "material/output", label: "Material Output", description: "Final shader output", color: "#4a9" },
                    { type: "value/float", label: "Float", description: "Float value", color: "#6a6" },
                    { type: "value/vec3", label: "Vector3", description: "3D vector", color: "#66a" },
                    { type: "value/color", label: "Color", description: "RGB color", color: "#a66" },
                ]
            },
            {
                name: "Math",
                nodes: [
                    { type: "math/add", label: "Add", description: "Add two values", color: "#aa6" },
                    { type: "math/subtract", label: "Subtract", description: "Subtract values", color: "#aa6" },
                    { type: "math/multiply", label: "Multiply", description: "Multiply values", color: "#aa6" },
                    { type: "math/divide", label: "Divide", description: "Divide values", color: "#aa6" },
                    { type: "math/lerp", label: "Lerp", description: "Linear interpolation", color: "#aa6" },
                ]
            },
            {
                name: "Texture",
                nodes: [
                    { type: "texture/sample", label: "Sample Texture", description: "Sample texture at UV", color: "#a6a" },
                    { type: "texture/normal", label: "Normal Map", description: "Normal map sample", color: "#a6a" },
                ]
            },
            {
                name: "PBR",
                nodes: [
                    { type: "pbr/albedo", label: "Albedo", description: "Base color", color: "#6aa" },
                    { type: "pbr/metallic", label: "Metallic", description: "Metallic value", color: "#6aa" },
                    { type: "pbr/roughness", label: "Roughness", description: "Roughness value", color: "#6aa" },
                    { type: "pbr/normal", label: "Normal", description: "Normal vector", color: "#6aa" },
                ]
            },
        ];
    }
    
    private function handleDragStart(nodeType: String, e: js.html.DragEvent): Void {
        e.dataTransfer.setData("nodeType", nodeType);
        e.dataTransfer.effectAllowed = "copy";
        props.onNodeDragStart(nodeType);
        trace("📦 Dragging node: " + nodeType);
    }
    
    override function render(): ReactElement {
        var categories = getCategories();
        
        return jsx('
            <div style={{
                width: "220px",
                background: "#2a2a2a",
                borderRight: "1px solid #1a1a1a",
                overflowY: "auto",
                userSelect: "none"
            }}>
                <div style={{
                    padding: "10px",
                    borderBottom: "1px solid #1a1a1a",
                    background: "#1a1a1a"
                }}>
                    <h3 style={{margin: 0, color: "#fff", fontSize: "13px"}}>
                        📦 Nodes
                    </h3>
                </div>
                
                {[for (category in categories) renderCategory(category)]}
            </div>
        ');
    }
    
    private function renderCategory(category: NodeCategory): ReactElement {
        return jsx('
            <div key={category.name} style={{marginBottom: "8px"}}>
                <div style={{
                    padding: "6px 10px",
                    background: "#333",
                    color: "#aaa",
                    fontSize: "11px",
                    fontWeight: "bold",
                    textTransform: "uppercase",
                    letterSpacing: "0.5px"
                }}>
                    {category.name}
                </div>
                <div>
                    {[for (node in category.nodes) renderNodeItem(node)]}
                </div>
            </div>
        ');
    }
    
    private function renderNodeItem(node: NodeInfo): ReactElement {
        return jsx('
            <div
                key={node.type}
                draggable={true}
                onDragStart={function(e) handleDragStart(node.type, e)}
                style={{
                    padding: "8px 10px",
                    margin: "2px 6px",
                    background: "#3a3a3a",
                    borderRadius: "4px",
                    cursor: "grab",
                    border: "1px solid transparent",
                    transition: "all 0.15s"
                }}
                onMouseOver={function(e: js.html.MouseEvent) {
                    var el = cast(e.currentTarget, js.html.Element);
                    el.style.background = "#4a4a4a";
                    el.style.borderColor = node.color;
                }}
                onMouseOut={function(e: js.html.MouseEvent) {
                    var el = cast(e.currentTarget, js.html.Element);
                    el.style.background = "#3a3a3a";
                    el.style.borderColor = "transparent";
                }}
            >
                <div style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "8px"
                }}>
                    <div style={{
                        width: "12px",
                        height: "12px",
                        borderRadius: "3px",
                        background: node.color,
                        flexShrink: 0
                    }}></div>
                    <div style={{flex: 1}}>
                        <div style={{
                            color: "#fff",
                            fontSize: "12px",
                            fontWeight: "500"
                        }}>
                            {node.label}
                        </div>
                        <div style={{
                            color: "#888",
                            fontSize: "10px",
                            marginTop: "2px"
                        }}>
                            {node.description}
                        </div>
                    </div>
                </div>
            </div>
        ');
    }
}