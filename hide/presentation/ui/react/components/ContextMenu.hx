package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;

typedef MenuItem = {
    var label: String;
    var ?icon: String;       // Опционально: класс иконки или SVG path
    var ?disabled: Bool;     // Если true, пункт некликабелен
    var ?separator: Bool;    // Если true, рисует разделительную линию
    var action: Void->Void;  // Функция, вызываемая при клике
}

typedef ContextMenuProps = {
    var x: Float;            // Координата X экрана
    var y: Float;            // Координата Y экрана
    var items: Array<MenuItem>;
    var onClose: Void->Void; // Коллбэк для закрытия меню
}

class ContextMenu extends ReactComponentOfProps<ContextMenuProps> {
    
    override function componentDidMount(): Void {
        // Закрытие по клику вне меню или Esc
        js.Browser.document.addEventListener("mousedown", handleGlobalClick);
        js.Browser.window.addEventListener("keydown", handleKeyDown);
    }

    override function componentWillUnmount(): Void {
        js.Browser.document.removeEventListener("mousedown", handleGlobalClick);
        js.Browser.window.removeEventListener("keydown", handleKeyDown);
    }

    private function handleGlobalClick(e:js.html.MouseEvent): Void {
        // Проверяем, был ли клик внутри самого меню
        var target = cast(e.target, js.html.Element);
        if (target != null && target.closest(".context-menu-root") == null) {
            props.onClose();
        }
    }

    private function handleKeyDown(e:js.html.KeyboardEvent): Void {
        if (e.key == "Escape") {
            props.onClose();
        }
    }

    override function render(): ReactElement {
        return jsx('
            <div 
                className="context-menu-root"
                style={{
                    position: "fixed",
                    left: props.x + "px",
                    top: props.y + "px",
                    zIndex: 9999,
                    background: "#252526",
                    border: "1px solid #454545",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.5)",
                    borderRadius: "4px",
                    padding: "4px 0",
                    minWidth: "180px",
                    fontSize: "12px",
                    color: "#cccccc"
                }}
            >
                {[for (item in props.items) renderItem(item)]}
            </div>
        ');
    }

    private function renderItem(item: MenuItem): ReactElement {
        if (item.separator) {
            return jsx('<div key={"sep-" + item.label} style={{height: "1px", background: "#454545", margin: "4px 0"}} />');
        }

        var isDisabled = item.disabled == true;
        var innerElement = item.icon != null ? jsx('<span style={{width: "16px", textAlign: "center"}}>{item.icon}</span>') : jsx('<span style={{width: "16px"}}></span>');
        return jsx('
            <div 
                key={item.label}
                className={isDisabled ? "context-item disabled" : "context-item"}
                onClick={!isDisabled ? item.action : null}
                style={{
                    padding: "4px 12px",
                    cursor: isDisabled ? "default" : "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                    opacity: isDisabled ? 0.5 : 1,
                    transition: "background 0.1s"
                }}
                onMouseOver={!isDisabled ? function(e) untyped e.currentTarget.style.background = "#094771" : null}
                onMouseOut={!isDisabled ? function(e) untyped e.currentTarget.style.background = "transparent" : null}
            >
                {innerElement}
                <span>{item.label}</span>
            </div>
        ');
    }
}