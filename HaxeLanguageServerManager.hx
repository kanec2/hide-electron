import js.node.ChildProcess;
import js.node.Buffer;
import js.node.Path;
import js.node.Fs;
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
    private static var isInitialized:Bool = false;  // ← НОВОЕ: отслеживаем инициализацию
    private static var projectRoot:String = "";
    private static var requestId:Int = 0;
    private static var pendingRequests:Map<Int, Dynamic->Void> = [];

    /**
     * Запускает Haxe Language Server.
     */
    public static function start(rootPath:String):Bool {
        if (isStarted) {
            trace("⚠️ [LSP] Already started");
            return true;
        }

        projectRoot = rootPath;
        
        // Путь к haxe-language-server
        var serverPath = Path.join(__dirname, "server.js");
        
        // Проверяем существование
        if (!Fs.existsSync(serverPath)) {
            trace("❌ [LSP] Server not found at: " + serverPath);
            return false;
        }

        trace("🚀 [LSP] Starting Haxe Language Server...");
        trace("📁 [LSP] Project root: " + rootPath);
        trace("📄 [LSP] Server path: " + serverPath);

        // Запускаем сервер как child process
        serverProcess = ChildProcess.spawn("node", [serverPath, "--stdio"], {
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
            isInitialized = false;
        });

        isStarted = true;
        // Инициализация LSP
        initialize();
        
        trace("✅ [LSP] Language Server started");
        return true;
    }

    /**
     * Инициализирует LSP протокол.
     * ВАЖНО: Вызывать ПОСЛЕ start()!
     */
    public static function initialize():Void {
        if (!isStarted || serverProcess == null) {
            trace("❌ [LSP] Cannot initialize: server not started");
            return;
        }

        // ✅ ИСПРАВЛЕНО: правильный rootUri для Windows и Unix
        var rootPathNormalized = projectRoot.split("\\").join("/");
        var rootUri = if (rootPathNormalized.charAt(0) == "/") {
            "file://" + rootPathNormalized;  // Unix: file:///home/user/project
        } else {
            "file:///" + rootPathNormalized; // Windows: file:///C:/Users/project
        };

        var params = {
            processId: untyped process.pid,
            rootUri: rootUri,
            rootPath: projectRoot,  // legacy, но некоторые серверы требуют
            capabilities: {
                textDocument: {
                    completion: {
                        completionItem: {
                            snippetSupport: true,
                            resolveSupport: { properties: ["documentation", "detail"] }
                        }
                    },
                    hover: { contentFormat: ["markdown", "plaintext"] },
                    signatureHelp: {},
                    definition: { linkSupport: true },
                    references: {},
                    documentSymbol: { hierarchicalDocumentSymbolSupport: true },
                    codeAction: {},
                    formatting: {},
                    publishDiagnostics: { 
                        relatedInformation: true,
                        tagSupport: { valueSet: [1, 2] }
                    },
                    synchronization: {
                        didSave: true,  // ← ВАЖНО: поддерживаем didSave
                        willSave: false,
                        willSaveWaitUntil: false
                    }
                },
                workspace: {
                    applyEdit: true,
                    configuration: true,  // ← ВАЖНО: сервер может запрашивать конфиг
                    didChangeConfiguration: { dynamicRegistration: true }
                }
            },
            initializationOptions: {}
        };

        // ✅ ИСПРАВЛЕНО: используем callback прямо в sendRequest
        sendRequest("initialize", params, function(result) {
            trace("✅ [LSP] Initialize response received");
            trace("   Server capabilities: " + haxe.Json.stringify(result != null ? Reflect.field(result, "capabilities") : null));
            
            // ✅ КРИТИЧНО: отправляем initialized notification
            sendNotification("initialized", {});
            isInitialized = true;
            trace("✅ [LSP] Initialized notification sent");
        });
    }

    /**
     * Останавливает Language Server.
     */
    public static function stop():Void {
        if (serverProcess != null) {
            sendRequest("shutdown", {}, function(_) {
                sendNotification("exit", {});
                haxe.Timer.delay(function() {
                    if (serverProcess != null) {
                        serverProcess.kill();
                        serverProcess = null;
                    }
                    isStarted = false;
                    isInitialized = false;
                    trace("🛑 [LSP] Language Server stopped");
                }, 500);
            });
        }
    }

    /**
     * Отправляет JSON-RPC запрос с callback'ом.
     * ✅ ИСПРАВЛЕНО: callback регистрируется ДО отправки (нет race condition)
     */
    public static function sendRequest(method:String, params:Dynamic, ?callback:Dynamic->Void):Int {
        if (serverProcess == null || !isStarted) {
            trace("❌ [LSP] Server not started");
            if (callback != null) callback(null);
            return -1;
        }

        requestId++;
        var id = requestId;
        
        // ✅ Регистрируем callback ДО отправки
        if (callback != null) {
            pendingRequests.set(id, callback);
            
            // ✅ Таймаут 10 секунд
            haxe.Timer.delay(function() {
                if (pendingRequests.exists(id)) {
                    pendingRequests.remove(id);
                    trace('⚠️ [LSP] Request $id ($method) timed out');
                    callback(null);
                }
            }, 10000);
        }

        var message = {
            jsonrpc: "2.0",
            id: id,
            method: method,
            params: params
        };

        sendJsonRpc(message);
        return id;
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
     * Уведомляет сервер об открытии файла.
     */
    public static function didOpen(uri:String, languageId:String, version:Int, text:String):Void {
        sendNotification("textDocument/didOpen", {
            textDocument: {
                uri: uri,
                languageId: languageId,
                version: version,
                text: text
            }
        });
    }

    /**
     * Уведомляет сервер об изменении файла.
     */
    public static function didChange(uri:String, version:Int, text:String):Void {
        sendNotification("textDocument/didChange", {
            textDocument: {
                uri: uri,
                version: version
            },
            contentChanges: [{ text: text }]
        });
    }

    /**
     * Уведомляет сервер о закрытии файла.
     */
    public static function didClose(uri:String):Void {
        sendNotification("textDocument/didClose", {
            textDocument: { uri: uri }
        });
    }

    /**
     * ✅ НОВОЕ: Уведомляет сервер о сохранении файла.
     */
    public static function didSave(uri:String, ?text:String):Void {
        sendNotification("textDocument/didSave", {
            textDocument: { uri: uri },
            text: text  // включаем текст, т.к. сервер может требовать
        });
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
            var headerEnd = buffer.indexOf("\r\n\r\n");
            if (headerEnd == -1) break;

            var header = buffer.substring(0, headerEnd);
            // ✅ ПРАВИЛЬНО (Haxe-синтаксис):
            var regex = ~/Content-Length: (\d+)/;
            if (!regex.match(header)) {
                trace("❌ [LSP] Invalid header: " + header);
                buffer = buffer.substring(headerEnd + 4);
                continue;
            }
            var length = Std.parseInt(regex.matched(1));
            var messageStart = headerEnd + 4;
            
            if (buffer.length < messageStart + length) break;

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
        // ✅ ИСПРАВЛЕНО: обрабатываем ошибки
        if (message.id != null && pendingRequests.exists(message.id)) {
            var callback = pendingRequests.get(message.id);
            pendingRequests.remove(message.id);
            
            if (message.error != null) {
                trace('❌ [LSP] Error for request ${message.id}: ${message.error.message}');
                if (callback != null) callback({ error: message.error });
            } else {
                if (callback != null) callback(message.result);
            }
            return;
        }

        // Запрос от сервера к клиенту
        if (message.id != null && message.method != null) {
            handleServerRequest(message);
            return;
        }

        // Notification от сервера
        if (message.method != null) {
            handleServerNotification(message);
            return;
        }
    }

    /**
     * Обрабатывает запрос от сервера к клиенту.
     * ✅ ИСПРАВЛЕНО: отвечаем на workspace/configuration
     */
    private static function handleServerRequest(message:Dynamic):Void {
        trace("📨 [LSP] Server request: " + message.method);
        
        switch (message.method) {
            case "workspace/configuration":
                // Сервер запрашивает конфигурацию — отвечаем дефолтами
                var items:Array<Dynamic> = message.params.items;
                var result = [for (_ in items) {}];
                sendResponse(message.id, result);
                trace("   ✅ Responded with default configuration");
                
            case "window/workDoneProgress/create":
                // Принимаем создание progress
                sendResponse(message.id, null);
                
            case "client/registerCapability":
                // Принимаем регистрацию capabilities
                sendResponse(message.id, null);
                
            default:
                // Пересылаем в renderer через IPC
                if (AutoWindow.window != null) {
                    AutoWindow.window.webContents.send("lsp:server-request", {
                        id: message.id,
                        method: message.method,
                        params: message.params
                    });
                }
        }
    }

    /**
     * Обрабатывает notification от сервера.
     * ✅ ИСПРАВЛЕНО: отдельно обрабатываем diagnostics
     */
    private static function handleServerNotification(message:Dynamic):Void {
        trace("📨 [LSP] Server notification: " + message.method);
        
        switch (message.method) {
            case "window/logMessage":
                trace("[LSP Log] " + message.params.message);
                
            case "window/showMessage":
                trace("[LSP Message] " + message.params.message);
                
            case "textDocument/publishDiagnostics":
                // ✅ Пересылаем diagnostics в renderer
                if (AutoWindow.window != null) {
                    AutoWindow.window.webContents.send("lsp:diagnostics", {
                        uri: message.params.uri,
                        diagnostics: message.params.diagnostics
                    });
                }
                
            default:
                if (AutoWindow.window != null) {
                    AutoWindow.window.webContents.send("lsp:notification", {
                        method: message.method,
                        params: message.params
                    });
                }
        }
    }
}