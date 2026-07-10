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

    function didSave(uri:String, ?text:String):Void;

    /** Проверяет, запущен ли сервер. */
    function isRunning():Bool;

    /**
     * Запрашивает семантические токены для документа.
     * @return SemanticTokensResult или null если не поддерживается
     */
    function semanticTokensFull(uri:String):Future<Null<SemanticTokensResult>>;
    
    /**
     * Запрашивает семантические токены для диапазона.
     */
    function semanticTokensRange(uri:String, range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}}):Future<Null<SemanticTokensResult>>;
    
    /**
     * Получает легенду семантических токенов.
     */
    function semanticTokensLegend():Future<Null<SemanticTokensLegend>>;
}