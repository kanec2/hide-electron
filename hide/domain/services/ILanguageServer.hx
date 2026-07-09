package hide.domain.services;

import hx.injection.Service;
import tink.core.Future;

/**
 * Доменный порт для Language Server.
 * НЕ знает ни про Electron, ни про IPC, ни про LSP protocol.
 */
interface ILanguageServer extends Service {
    /**
     * Запускает сервер для указанного проекта.
     */
    function start(rootPath:String):Future<Bool>;
    
    /**
     * Останавливает сервер.
     */
    function stop():Void;
    
    /**
     * Уведомляет сервер об открытии файла.
     */
    function didOpen(uri:String, languageId:String, version:Int, text:String):Void;
    
    /**
     * Уведомляет сервер об изменении файла.
     */
    function didChange(uri:String, version:Int, text:String):Void;
    
    /**
     * Уведомляет сервер о закрытии файла.
     */
    function didClose(uri:String):Void;
    
    /**
     * Запрашивает автодополнение.
     */
    function completion(uri:String, line:Int, character:Int):Future<Array<CompletionItem>>;
    
    /**
     * Запрашивает hover-информацию.
     */
    function hover(uri:String, line:Int, character:Int):Future<Null<HoverInfo>>;
    
    /**
     * Запрашивает переход к определению.
     */
    function definition(uri:String, line:Int, character:Int):Future<Null<Location>>;
    
    /**
     * Подписка на диагностику (ошибки, предупреждения).
     */
    function onDiagnostics(callback:String->Array<Diagnostic>->Void):Void;
}

typedef CompletionItem = {
    var label:String;
    var kind:Int;
    var ?detail:String;
    var ?documentation:String;
    var ?insertText:String;
}

typedef HoverInfo = {
    var contents:String;
    var ?range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
}

typedef Location = {
    var uri:String;
    var range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
}

typedef Diagnostic = {
    var range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
    var severity:Int;  // 1=Error, 2=Warning, 3=Info, 4=Hint
    var message:String;
    var ?source:String;
}