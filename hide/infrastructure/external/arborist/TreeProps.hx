// hide/infrastructure/external/ReactArborist.hx
package hide.infrastructure.external.arborist;
import react.ReactComponent;
import react.ReactMacro.jsx;
typedef TreeProps<T> = {
    /* Data Options */
    var ?data:Array<T>;
    var ?initialData:Array<T>;

    /* Data Handlers */
    var ?onCreate:(NodeApi<T>, String, String) -> Void; // (node, name, type)
    var ?onMove:(MoveHandlerArgs<T>) -> Void;
    var ?onRename:(NodeApi<T>, String) -> Void; // (node, newName)
    var ?onDelete:(DeleteHandlerArgs<T>) -> Void;

    /* Renderers */
    var ?children:(NodeApi<T>) -> ReactElement; // NodeRenderer
    var ?renderRow:Dynamic -> ReactElement;
    var ?renderDragPreview:Dynamic -> ReactElement;
    var ?renderCursor:Dynamic -> ReactElement;
    var ?renderContainer:Dynamic -> ReactElement;

    /* Sizes */
    var ?rowHeight:Int;
    var ?overscanCount:Int;
    var ?width:Dynamic; // number | string
    var ?height:Int;
    var ?indent:Int;
    var ?paddingTop:Int;
    var ?paddingBottom:Int;
    var ?padding:Int;

    /* Config */
    var ?childrenAccessor:Dynamic; // string | (T -> Array<T>)
    var ?idAccessor:Dynamic;       // string | (T -> String)
    var ?openByDefault:Bool;
    var ?selectionFollowsFocus:Bool;
    var ?disableMultiSelection:Bool;
    var ?disableDeselectOnClick:Bool;
    var ?disableSelect:Dynamic;    // string | Bool | (T -> Bool)
    var ?disableEdit:Dynamic;      // string | Bool | (T -> Bool)
    var ?disableDrag:Dynamic;      // string | Bool | (T -> Bool)
    var ?disableDrop:Dynamic;      // string | Bool | (args -> Bool)

    /* Event Handlers */
    var ?onActivate:(NodeApi<T>) -> Void;
    var ?onSelect:(Array<NodeApi<T>>) -> Void;
    var ?onScroll:Dynamic -> Void;
    var ?onToggle:(String) -> Void;
    var ?onFocus:(NodeApi<T>) -> Void;

    /* Selection */
    var ?selection:Null<String>;

    /* Open State */
    var ?initialOpenState:Dynamic; // OpenMap

    /* Search */
    var ?searchTerm:Null<String>;
    var ?searchMatch:(NodeApi<T>, String) -> Bool;

    /* Extra */
    var ?className:Null<String>;
    var ?rowClassName:Null<String>;

    /* Tree container mouse events */
    var ?onClick:(js.html.MouseEvent) -> Void;
    var ?onContextMenu:(js.html.MouseEvent) -> Void;

    /* DND */
    var ?dndRootElement:js.html.Node;
    var ?dndBackend:Dynamic;
    var ?dndManager:Dynamic;
    var ?dragType:Dynamic; // string | (NodeApi<T> -> String)
}