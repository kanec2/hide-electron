package src.main.ipc;

import electron.main.IpcMain;
import electron.IpcMainEvent;
import src.main.services.ServiceLocator;
import hide.shared.types.IpcResponse;

class LanguageServerHandlers {
    public static function setup():Void {
        IpcMain.handle("lsp:start", onLspStart);
        IpcMain.handle("lsp:stop", onLspStop);
        IpcMain.handle("lsp:request", onLspRequest);
        
        IpcMain.on("lsp:notification", onLspNotification);
        IpcMain.on("lsp:response", onLspResponse);
        IpcMain.on("lsp:didSave", onLspDidSave);
        IpcMain.on("lsp:didOpen", onLspDidOpen);
        IpcMain.on("lsp:didChange", onLspDidChange);
        IpcMain.on("lsp:didClose", onLspDidClose);
        IpcMain.on("lsp:completion", onLspCompletion);
        IpcMain.on("lsp:hover", onLspHover);
        IpcMain.on("lsp:definition", onLspDefinition);

        IpcMain.on("lsp:semanticTokensFull", onLspSemanticTokensFull);
        IpcMain.on("lsp:semanticTokensRange", onLspSemanticTokensRange);
        IpcMain.on("lsp:semanticTokensLegend", onLspSemanticTokensLegend);
    }

    // Запуск LSP
    private static function onLspStart(event:Dynamic, rootPath:String) {
        HaxeLanguageServerManager.start(rootPath);
        HaxeLanguageServerManager.initialize();
        return { success: true };
    }

    // Остановка LSP
    private static function onLspStop(event:Dynamic) {
        HaxeLanguageServerManager.stop();
        return { success: true };
    };

    // Отправка запроса в LSP
    private static function onLspRequest(event:Dynamic, data:Dynamic) {
        var id = HaxeLanguageServerManager.sendRequest(data.method, data.params);
        return { id: id };
    };

    // Отправка notification в LSP
    private static function onLspNotification(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.sendNotification(data.method, data.params);
        event.returnValue = null;
    };

    // Ответ на запрос от сервера
    private static function onLspResponse(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.sendResponse(data.id, data.result);
        event.returnValue = null;
    };

    // В setupIpc() добавить:
    private static function onLspDidSave(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.didSave(data.uri, data.text);
        event.returnValue = null;
    };

    // Открытие файла в LSP (didOpen)
    private static function onLspDidOpen(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.sendNotification("textDocument/didOpen", {
            textDocument: {
                uri: data.uri,
                languageId: data.languageId,
                version: data.version,
                text: data.text
            }
        });
        event.returnValue = null;
    };

    // Изменение файла в LSP (didChange)
    private static function onLspDidChange(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.sendNotification("textDocument/didChange", {
            textDocument: {
                uri: data.uri,
                version: data.version
            },
            contentChanges: data.contentChanges
        });
        event.returnValue = null;
    };

        // Закрытие файла в LSP (didClose)
    private static function onLspDidClose(event:IpcMainEvent, data:Dynamic) {
        HaxeLanguageServerManager.sendNotification("textDocument/didClose", {
            textDocument: {
                uri: data.uri
            }
        });
        event.returnValue = null;
    };

        // Запрос автодополнения
    private static function onLspDidCompletion(event:Dynamic, data:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            HaxeLanguageServerManager.sendRequest("textDocument/completion", {
                textDocument: { uri: data.uri },
                position: { line: data.line, character: data.character },
                context: data.context
            }, function(result) {
                resolve(result);
            });
        });
    };

    // Запрос hover информации
    private static function onLspHover(event:Dynamic, data:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            HaxeLanguageServerManager.sendRequest("textDocument/hover", {
                textDocument: { uri: data.uri },
                position: { line: data.line, character: data.character }
            }, function(result) {
                resolve(result);
            });
        });
    };

    // Запрос перехода к определению
    private static function onLspDefinition(event:Dynamic, data:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            HaxeLanguageServerManager.sendRequest("textDocument/definition", {
                textDocument: { uri: data.uri },
                position: { line: data.line, character: data.character }
            }, function(result) {
                resolve(result);
            });
        });
    };

    // Semantic Tokens
    private static function onLspSemanticTokensFull(event:Dynamic, data:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            HaxeLanguageServerManager.sendRequest("textDocument/semanticTokens/full", {
                textDocument: { uri: data.uri }
            }, function(result) {
                resolve(result);
            });
        });
    };

    private static function onLspSemanticTokensRange(event:Dynamic, data:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            HaxeLanguageServerManager.sendRequest("textDocument/semanticTokens/range", {
                textDocument: { uri: data.uri },
                range: data.range
            }, function(result) {
                resolve(result);
            });
        });
    };

    private static function onLspSemanticTokensLegend(event:Dynamic) {
        return new js.lib.Promise(function(resolve, reject) {
            // Возвращаем кэшированную легенду из initialize
            resolve(HaxeLanguageServerManager.getSemanticTokensLegend());
        });
    };
}