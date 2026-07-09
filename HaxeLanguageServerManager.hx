import js.node.ChildProcess;
import js.node.Buffer;
import js.node.Path;
import electron.main.IpcMain;
import electron.IpcMainEvent;

@:native("__dirname") extern var __dirname:String;

/**
 * Менеджер Haxe Language Server.
 * Запускает LSP сервер как child process и маршрутизирует сообщения
 * между Monaco Editor (renderer) и Language Server через IPC.
 */
class HaxeLanguageServerManager {
    private static var serverProcess:js.node.child_process.ChildProcess = null;
    private static var buffer:String = "";
    private static var isStarted:Bool = false;
    private static var projectRoot:String = "";
    private static var requestId:Int = 0;
    private static var pendingRequests:Map<Int, Dynamic->Void> = [];

    /**
     * Запускает Haxe Language Server.
     * @param rootPath Путь к корню проекта (для hxml файлов)
     */
    public static function start(rootPath:String):Void {
        if (isStarted) {
            trace("⚠️ [LSP] Already started");
            return;
        }

        projectRoot = rootPath;
        
        // Путь к haxe-language-server (устанавливается через npm)
        var serverPath = Path.join(__dirname, "node_modules", "haxe-language-server", "bin", "server.js");
        
        trace("🚀 [LSP] Starting Haxe Language Server...");
        trace("📁 [LSP] Project root: " + rootPath);
        trace("📄 [LSP] Server path: " + serverPath);

        // Запускаем сервер как child process
        serverProcess = ChildProcess.spawn("node", [serverPath], {
            cwd: rootPath,
            stdio: ["pipe", "pipe", "pipe"]
        });

        // Обработка stdout (ответы от LSP)
        serverProcess.stdout.on("data", function(data:Buffer) {
            buffer += data.toString();
            processMessages();
        });

        // Обработка stderr (логи сервера)
        serverProcess.stderr.on("data", function(data:Buffer) {
            trace("[LSP Server] " + data.toString());
        });

        // Обработка ошибок
        serverProcess.on("error", function(err:Dynamic) {
            trace("❌ [LSP] Server error: " + err);
        });

        serverProcess.on("exit", function(code:Int) {
            trace("⚠️ [LSP] Server exited with code: " + code);
            isStarted = false;
        });

        isStarted = true;
        trace("✅ [LSP] Language Server started");
    }

    /**
     * Останавливает Language Server.
     */
    public static function stop():Void {
        if (serverProcess != null) {
            // Отправляем shutdown request
            sendRequest("shutdown", {});
            
            // Даём серверу время на завершение
            haxe.Timer.delay(function() {
                if (serverProcess != null) {
                    serverProcess.kill();
                    serverProcess = null;
                }
                isStarted = false;
                trace("🛑 [LSP] Language Server stopped");
            }, 1000);
        }
    }

    /**
     * Отправляет JSON-RPC запрос в Language Server.
     */
    public static function sendRequest(method:String, params:Dynamic):Int {
        if (serverProcess == null || !isStarted) {
            trace("❌ [LSP] Server not started");
            return -1;
        }

        requestId++;
        var message = {
            jsonrpc: "2.0",
            id: requestId,
            method: method,
            params: params
        };

        sendJsonRpc(message);
        return requestId;
    }

    /**
     * Отправляет JSON-RPC notification (без id, без ответа).
     */
    public static function sendNotification(method:String, params:Dynamic):Void {
        if (serverProcess == null || !isStarted) {
            trace("❌ [LSP] Server not started");
            return;
        }

        var message = {
            jsonrpc: "2.0",
            method: method,
            params: params
        };

        sendJsonRpc(message);
    }

    /**
     * Отправляет JSON-RPC ответ на запрос от сервера.
     */
    public static function sendResponse(id:Dynamic, result:Dynamic):Void {
        if (serverProcess == null) return;

        var message = {
            jsonrpc: "2.0",
            id: id,
            result: result
        };

        sendJsonRpc(message);
    }

    /**
     * Сериализует и отправляет JSON-RPC сообщение.
     */
    private static function sendJsonRpc(message:Dynamic):Void {
        var json = haxe.Json.stringify(message);
        var contentLength = Buffer.byteLength(json, "utf8");
        var header = 'Content-Length: $contentLength\r\n\r\n';
        
        serverProcess.stdin.write(header + json);
    }

    /**
     * Парсит и обрабатывает сообщения от Language Server.
     */
    private static function processMessages():Void {
        while (true) {
            // Ищем конец заголовка
            var headerEnd = buffer.indexOf("\r\n\r\n");
            if (headerEnd == -1) break;

            // Парсим Content-Length
            var header = buffer.substring(0, headerEnd);
            var match = ~/Content-Length: (\d+)/.exec(header);
            if (match == null) {
                trace("❌ [LSP] Invalid header: " + header);
                break;
            }

            var length = Std.parseInt(match[1]);
            var messageStart = headerEnd + 4;
            
            // Проверяем, есть ли полное сообщение в буфере
            if (buffer.length < messageStart + length) break;

            // Извлекаем JSON
            var messageJson = buffer.substring(messageStart, messageStart + length);
            buffer = buffer.substring(messageStart + length);

            try {
                var message:Dynamic = haxe.Json.parse(messageJson);
                handleMessage(message);
            } catch (e:Dynamic) {
                trace("❌ [LSP] Failed to parse message: " + e);
            }
        }
    }

    /**
     * Обрабатывает одно JSON-RPC сообщение от сервера.
     */
    private static function handleMessage(message:Dynamic):Void {
        // Если это ответ на наш запрос
        if (message.id != null && pendingRequests.exists(message.id)) {
            var callback = pendingRequests.get(message.id);
            pendingRequests.remove(message.id);
            if (callback != null) callback(message.result);
            return;
        }

        // Если это запрос от сервера к клиенту
        if (message.id != null && message.method != null) {
            handleServerRequest(message);
            return;
        }

        // Если это notification от сервера
        if (message.method != null) {
            handleServerNotification(message);
            return;
        }
    }

    /**
     * Обрабатывает запрос от сервера к клиенту.
     */
    private static function handleServerRequest(message:Dynamic):Void {
        trace("📨 [LSP] Server request: " + message.method);
        
        // Пересылаем в renderer через IPC
        if (AutoWindow.window != null) {
            AutoWindow.window.webContents.send("lsp:server-request", {
                id: message.id,
                method: message.method,
                params: message.params
            });
        }
    }

    /**
     * Обрабатывает notification от сервера.
     */
    private static function handleServerNotification(message:Dynamic):Void {
        trace("📨 [LSP] Server notification: " + message.method);
        
        // Пересылаем в renderer через IPC
        if (AutoWindow.window != null) {
            AutoWindow.window.webContents.send("lsp:notification", {
                method: message.method,
                params: message.params
            });
        }
    }

    /**
     * Регистрирует callback для ожидания ответа на запрос.
     */
    public static function waitForResponse(id:Int, callback:Dynamic->Void):Void {
        pendingRequests.set(id, callback);
    }

    /**
     * Инициализирует Language Server Protocol.
     * Вызывается после start().
     */
    public static function initialize():Void {
        var params = {
            processId: js.node.Process.pid,
            rootUri: "file://" + projectRoot,
            capabilities: {
                textDocument: {
                    completion: {
                        completionItem: {
                            snippetSupport: true
                        }
                    },
                    hover: {},
                    signatureHelp: {},
                    definition: {},
                    references: {},
                    documentSymbol: {},
                    codeAction: {},
                    formatting: {},
                    publishDiagnostics: {
                        relatedInformation: true
                    }
                },
                workspace: {
                    applyEdit: true,
                   DidChangeConfiguration: {
                        dynamicRegistration: true
                    }
                }
            }
        };

        sendRequest("initialize", params);
        trace("✅ [LSP] Initialize request sent");
    }
}