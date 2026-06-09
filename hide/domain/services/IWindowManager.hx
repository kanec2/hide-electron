package hide.domain.services;

import hide.domain.valueobjects.WindowBounds;
import hide.domain.enums.WindowEvent;
import hx.injection.Service;
/**
 * Порт (интерфейс) для управления нативным окном.
 * НЕ знает ничего про Electron, NW.js или DOM.
 */
interface IWindowManager extends Service{
    function resizeBy(dw:Int, dh:Int):Void;
    function moveTo(x:Int, y:Int):Void;
    function maximize():Void;
    function unmaximize():Void;
    function focus():Void;
    function blur():Void;
    function setTitle(title:String):Void;
    function getTitle():String;
    function enterFullscreen():Void;
    function leaveFullscreen():Void;
    function showDevTools():Void;
    
    function on(event:WindowEvent, cb:Dynamic->Void):Void;
    function off(event:WindowEvent, cb:Dynamic->Void):Void;
    
    function getBounds():WindowBounds;
    function dispose():Void;
}