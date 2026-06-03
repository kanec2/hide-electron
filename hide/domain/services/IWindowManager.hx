package hide.domain.services;

import hide.domain.valueobjects.WindowBounds;
import hide.domain.enums.WindowEvent;

/**
 * Порт (интерфейс) для управления нативным окном.
 * НЕ знает ничего про Electron, NW.js или DOM.
 */
interface IWindowManager {
    function getBounds():WindowBounds;
    function resizeBy(dw:Int, dh:Int):Void;
    function resizeTo(w:Int, h:Int):Void;
    function moveTo(x:Int, y:Int):Void;
    function setFullscreen(value:Bool):Void;
    function maximize():Void;
    function unmaximize():Void;
    function minimize():Void;
    function restore():Void;
    function focus():Void;
    function blur():Void;
    function setTitle(title:String):Void;
    
    function on(event:WindowEvent, callback:Dynamic->Void):Void;
    function off(event:WindowEvent, callback:Dynamic->Void):Void;
}