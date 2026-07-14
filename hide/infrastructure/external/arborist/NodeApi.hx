// hide/infrastructure/external/ReactArborist.hx
package hide.infrastructure.external.arborist;

extern class NodeApi<T> {
    var tree:Dynamic;
    var id:String;
    var data:T;
    var level:Int;
    var children:Null<Array<NodeApi<T>>>;
    var parent:Null<NodeApi<T>>;
    var isDraggable:Bool;
    var rowIndex:Null<Int>;

    // Геттеры (в Haxe extern они объявляются как var)
    var isRoot:Bool;
    var isLeaf:Bool;
    var isInternal:Bool;
    var isOpen:Bool;
    var isClosed:Bool;
    var isEditable:Bool;
    var isSelectable:Bool;
    var isEditing:Bool;
    var isSelected:Bool;
    var isOnlySelection:Bool;
    var isSelectedStart:Bool;
    var isSelectedEnd:Bool;
    var isFocused:Bool;
    var isDragging:Bool;
    var willReceiveDrop:Bool;
    
    var state:Dynamic;
    var childIndex:Int;
    var next:Null<NodeApi<T>>;
    var prev:Null<NodeApi<T>>;
    var nextSibling:Null<NodeApi<T>>;

    // Методы
    function isAncestorOf(node:Null<NodeApi<T>>):Bool;
    function select():Void;
    function deselect():Void;
    function selectMulti():Void;
    function selectContiguous():Void;
    function activate():Void;
    function focus():Void;
    function toggle():Void;
    function open():Void;
    function openParents():Void;
    function close():Void;
    function submit(value:String):Void;
    function reset():Void;
    function clone():NodeApi<T>;
    function edit():Void;
    function handleClick(e:Dynamic):Void;
}