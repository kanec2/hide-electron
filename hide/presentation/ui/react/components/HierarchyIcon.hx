package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
// Простой enum для типизации типов объектов
enum ObjectType {
    Camera;
    Light;
    Mesh;
    Player;
    Default;
}

typedef IconProps = {
    var type: ObjectType;
}

class HierarchyIcon extends ReactComponentOfProps<IconProps> {
    
    override function render(): ReactElement {
        var color = "#9ca3af"; // default gray
        var svgPath = "";

        switch (props.type) {
            case Camera:
                color = "#60a5fa"; // blue-400
                svgPath = "M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z M12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z";
            case Light:
                color = "#facc15"; // yellow-400
                svgPath = "M12 2v2m0 16v2M4.93 4.93l1.41 1.41m11.32 11.32l1.41 1.41M2 12h2m16 0h2M4.93 19.07l1.41-1.41m11.32-11.32l1.41-1.41M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z";
            case Player:
                color = "#4ade80"; // green-400
                svgPath = "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 7a4 4 0 1 0 0-8 4 4 0 0 0 0 8z";
            case Mesh:
                color = "#d1d5db"; // gray-300
                svgPath = "M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z M3.27 6.96L12 12.01l8.73-5.05 M12 22.08V12";
            default:
                svgPath = "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z M14 2v6h6 M16 13H8 M16 17H8 M10 9H8";
        }

        return jsx('
            <svg 
                width="16" 
                height="16" 
                viewBox="0 0 24 24" 
                fill="none" 
                stroke={color} 
                strokeWidth="2" 
                strokeLinecap="round" 
                strokeLinejoin="round"
                style={{ marginRight: "6px", flexShrink: "0" }}
            >
                <path d={svgPath} />
            </svg>
        ');
    }
}