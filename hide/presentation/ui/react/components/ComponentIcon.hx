package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;

typedef ComponentIconProps = {
    var className: String; // Полное имя класса, например "hide.engine.domain.entities.MeshRenderer"
}

class ComponentIcon extends ReactComponentOfProps<ComponentIconProps> {
    
    override function render(): ReactElement {
        var color = "#9ca3af"; // default gray
        var svgPath = "";

        switch (props.className) {
            case "hide.engine.domain.entities.MeshRenderer":
                color = "#60a5fa"; // blue-400 (как в Hierarchy)
                // Иконка куба/меши
                svgPath = "M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z M3.27 6.96L12 12.01l8.73-5.05 M12 22.08V12";
            case "hide.engine.domain.entities.Rigidbody":
                color = "#facc15"; // yellow-400
                // Иконка физики/гравитации (шар со стрелкой вниз)
                svgPath = "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0-4a2 2 0 1 1 0-4 2 2 0 0 1 0 4z"; 
                // Альтернатива: простая стрелка вниз для гравитации
                // svgPath = "M12 5v14m-7-7l7 7 7-7";
            case "hide.engine.domain.entities.Transform":
                 color = "#d1d5db"; // gray-300
                 // Иконка осей координат или перемещения
                 svgPath = "M3 12h18M12 3v18m-9-9l4-4m5 5l4-4m-9 9l4 4m5-5l4 4";
            default:
                // Иконка для неизвестного компонента (шестеренка или пазл)
                svgPath = "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z";
        }

        return jsx('
            <svg 
                width="14" 
                height="14" 
                viewBox="0 0 24 24" 
                fill="none" 
                stroke={color} 
                strokeWidth="2" 
                strokeLinecap="round" 
                strokeLinejoin="round"
                style={{ marginRight: "6px", flexShrink: "0", verticalAlign: "middle" }}
            >
                <path d={svgPath} />
            </svg>
        ');
    }
}