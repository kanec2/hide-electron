package hide.core;

/**
 * Интерфейс, скрывающий различия между NW.js и Electron.
 * Все платформо-зависимые вызовы идут через этот интерфейс.
 */
interface IIdeBackend {
    // === Инициализация ===
    function init():Void;
    function isReady():Bool;

    // === Окна ===
    function openWindow(url:String, options:Dynamic, ?id:String):Void;
    function closeWindow(?id:String):Void;
    function focusWindow(?id:String):Void;
    function getCurrentWindowId():String;

    // === Меню ===
    function createMenu(menuData:Array<Dynamic>):Void;
    function onMenuClick(handler:String->Void):Void;
    function updateMenuLabel(itemId:String, newLabel:String):Void;
    function setMenuItemEnabled(itemId:String, enabled:Bool):Void;

    // === Файловая система ===
    function readFile(path:String, ?onComplete:String->Void, ?onError:String->Void):Void;
    function writeFile(path:String, content:String, ?onComplete:Bool->Void, ?onError:String->Void):Void;
    function watchPath(path:String, onChange:String->Void):Void;
    function unwatchPath(path:String):Void;

    // === Приложение ===
    function clearCache():Void;
    function reload():Void;
    function quit():Void;
    function getArgv():Array<String>;
    function getAppPath():String;
    function showDevTools():Void;

    // === IPC (только для Electron, в NW.js — заглушки) ===
    function sendToMain(channel:String, ?data:Dynamic):Void;
    function onFromMain(channel:String, handler:Dynamic->Void):Void;


}