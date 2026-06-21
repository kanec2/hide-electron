// infrastructure/external/litegraph/LiteGraph.hx
package hide.infrastructure.external.litegraph;

import js.html.CanvasElement;
import js.html.Element;

@:jsRequire("litegraph.js")
extern class LiteGraph {
    // Constants
    static var VERSION:Float;
    static var CANVAS_GRID_SIZE:Float;
    static var NODE_TITLE_HEIGHT:Float;
    static var NODE_TITLE_TEXT_Y:Float;
    static var NODE_SLOT_HEIGHT:Float;
    static var NODE_WIDTH:Float;
    static var NODE_MIN_WIDTH:Float;
    static var NODE_COLLAPSED_RADIUS:Float;
    static var NODE_COLLAPSED_WIDTH:Float;
    static var NODE_TITLE_COLOR:String;
    static var NODE_SELECTED_TITLE_COLOR:String;
    static var NODE_TEXT_SIZE:Float;
    static var NODE_TEXT_COLOR:String;
    static var NODE_TEXT_HIGHLIGHT_COLOR:String;
    static var NODE_SUBTEXT_SIZE:Float;
    static var NODE_DEFAULT_COLOR:String;
    static var NODE_DEFAULT_BGCOLOR:String;
    static var NODE_DEFAULT_BOXCOLOR:String;
    static var NODE_DEFAULT_SHAPE:String;
    static var NODE_BOX_OUTLINE_COLOR:String;
    static var NODE_ERROR_COLOUR:String;
    static var DEFAULT_GROUP_FONT:Float;
    static var WIDGET_BGCOLOR:String;
    static var WIDGET_OUTLINE_COLOR:String;
    static var WIDGET_TEXT_COLOR:String;
    static var WIDGET_SECONDARY_TEXT_COLOR:String;
    static var LINK_COLOR:String;
    static var EVENT_LINK_COLOR:String;
    static var CONNECTING_LINK_COLOR:String;
    
    // Enums
    static var UP:String;
    static var DOWN:String;
    static var LEFT:String;
    static var RIGHT:String;
    static var CENTER:String;
    static var STRAIGHT_LINK:String;
    static var LINEAR_LINK:String;
    static var SPLINE_LINK:String;
    static var NORMAL_TITLE:String;
    static var NO_TITLE:String;
    static var TRANSPARENT_TITLE:String;
    static var AUTOHIDE_TITLE:String;
    static var VERTICAL:String;
    static var HORIZONTAL:String;
    static var ALWAYS:String;
    static var ON_EVENT:String;
    static var NEVER:String;
    static var ON_TRIGGER:String;
    static var OPACITY_ZERO:String;
    static var OPACITY_NORMAL:String;
    static var OPACITY_HOVER:String;
    static var OPACITY_ACTIVE:String;
    
    // Settings
    static var alt_drag_do_clone:Bool;
    static var link_type_menu:Bool;
    static var search_filter_enabled:Bool;
    static var search_show_all_on_open:Bool;
    static var auto_load_slot_types:Bool;
    static var registered_slot_in_types:Dynamic;
    static var slot_types_in:Dynamic;
    static var slot_types_out:Dynamic;
    static var slot_types_default_in:Dynamic;
    static var slot_types_default_out:Dynamic;
    static var registered_node_types:Dynamic;
    static var node_types_by_file_extension:Dynamic;
    static var Nodes:Dynamic;
    static var Globals:Dynamic;
    
    // Methods
    static function registerNodeType(type:String, nodeClass:Dynamic):Void;
    static function unregisterNodeType(type:String):Void;
    static function registerNodeTypeByMethod(method:Dynamic, type:String):Void;
    static function getNodeType(type:String):Dynamic;
    static function getNodeTypesCategories(separator:String):Array<String>;
    static function createNode(type:String, ?title:String, ?skipEvents:Bool):LGraphNode;
    static function trigger(action:String, params:Dynamic):Void;
    static function on(action:String, callback:Dynamic->Void):Void;
    static function compareObjects(a:Dynamic, b:Dynamic):Bool;
    static function distance(a:Array<Float>, b:Array<Float>):Float;
    static function colorToString(color:Array<Float>):String;
    static function isInsideRectangle(x:Float, y:Float, left:Float, top:Float, width:Float, height:Float):Bool;
    static function growBounding(bounding:Array<Float>, x:Float, y:Float):Void;
    static function isPointInRectangle(x:Float, y:Float, rect:Array<Float>):Bool;
    static function overlapBounding(a:Array<Float>, b:Array<Float>):Bool;
    static function extendClass(classObject:Dynamic, superClass:Dynamic):Void;
    static function getParameterNames(func:String):Array<String>;
    static function cloneObject(obj:Dynamic, ?visited:Dynamic):Dynamic;
    static function loadGraphInformation(info:Dynamic):Dynamic;
    static function downloadFile(filename:String, data:String):Void;
    static function toFixed(number:Float, digits:Int):String;
    static function createDialog(html:String, ?options:Dynamic):Element;
    static function closeAllContextMenus(?refWindow:Dynamic):Void;
    static function setTooltip(text:String):Void;
    static function isInsideBox(x:Float, y:Float, box:Array<Float>):Bool;
    static function overlapBoxes(a:Array<Float>, b:Array<Float>):Bool;
    static function createCanvas(width:Int, height:Int, ?alpha:Bool):CanvasElement;
    static function getMousePosition(e:js.html.MouseEvent):Array<Float>;
    static function getContextMenuOptions(x:Float, y:Float):Dynamic;
    static function getCanvasMenuOptions(?context:Dynamic, ?options:Dynamic):Dynamic;
    static function showContextMenu(items:Array<Dynamic>, x:Float, y:Float, ?options:Dynamic):Void;
    static function getSlotMenuOptions(slot:Dynamic):Array<Dynamic>;
}