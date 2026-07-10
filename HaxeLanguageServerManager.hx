import hide.domain.services.SemanticTokensLegend;
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
    private static var semanticTokensLegend:Null<SemanticTokensLegend> = null;
    private static var serverProcess:js.node.child_process.ChildProcess = null;
    private static var buffer:String = "";
    private static var isStarted:Bool = false;
    private static var isInitialized:Bool = false;  // ← НОВОЕ: отслеживаем инициализацию
    private static var projectRoot:String = "";
    private static var requestId:Int = 0;
    private static var pendingRequests:Map<Int, Dynamic->Void> = [];

    private static var registeredCapabilities:Array<Dynamic> = [];
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
        serverProcess = ChildProcess.spawn("node", [serverPath], {
            cwd: rootPath,
            stdio: ["pipe", "pipe", "pipe"]
        });

        // Обработка stdout (ответы от LSP)
        serverProcess.stdout.on("data", function(data:Buffer) {
            buffer += data;
    
            // ✅ Парсим все полные сообщения из буфера
            while (true) {
                // Ищем конец заголовка
                var headerEnd = buffer.indexOf("\r\n\r\n");
                if (headerEnd == -1) {
                    // Заголовок ещё не полностью получен
                    break;
                }
                
                var header = buffer.substring(0, headerEnd);
                
                // Парсим Content-Length
                var headerRegex = ~/Content-Length:\s*(\d+)/i;
                if (!headerRegex.match(header)) {
                    trace("❌ [LSP] Invalid header: " + header);
                    buffer = buffer.substring(headerEnd + 4);
                    continue;
                }

                var contentLength = Std.parseInt(headerRegex.matched(1));
                
                var messageStart = headerEnd + 4; // После \r\n\r\n
                var messageEnd = messageStart + contentLength;
                
                // Проверяем, есть ли полное сообщение в буфере
                if (buffer.length < messageEnd) {
                    // Сообщение ещё не полностью получено
                    break;
                }
                
                // Извлекаем сообщение
                var message = buffer.substring(messageStart, messageEnd);
                
                // Удаляем обработанное сообщение из буфера
                buffer = buffer.substring(messageEnd);
                
                // Парсим JSON
                try {
                    var json = haxe.Json.parse(message);
                    handleMessage(json);
                } catch (e:Dynamic) {
                    trace("❌ [LSP] Failed to parse message: " + e);
                    trace("   Message: " + message.substring(0, 200));
                }
            }
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

    var rootPathNormalized = projectRoot.split("\\").join("/");
    var rootUri = if (rootPathNormalized.charAt(0) == "/") {
        "file://" + rootPathNormalized;
    } else {
        "file:///" + rootPathNormalized;
    };

    var params = {
    processId: untyped process.pid,
    rootUri: rootUri,
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
                didSave: true,
                willSave: false,
                willSaveWaitUntil: false
            },
            semanticTokens: {
                requests: {
                    full: true,
                    range: false
                },
                formats: ["relative"],
                overlappingTokenSupport: false,
                multilineTokenSupport: false,
                serverCancelSupport: false,
                augmentsSyntaxTokens: true
            }
        },
        workspace: {
            applyEdit: true,
            configuration: true,
            didChangeConfiguration: { dynamicRegistration: true }  // ← Это можно оставить
        }
    },
    initializationOptions: {
        displayServerConfig: {
            path: "haxe",
            env: {},
            arguments: [],
            print: {
                completion: false,
                reusing: false
            },
            useSocket: true
        },
        displayArguments: [],
        haxelibConfig: {
            executable: "haxelib"
        },
        sendMethodResults: false,
        experimentalClientCapabilities: {
            supportedCommands: []
        }
    }
};

    sendRequest("initialize", params, function(result) {
        trace("✅ [LSP] Initialize response received");
        
        if (result != null && result.capabilities != null) {
            var caps = result.capabilities;
            
            if (Reflect.hasField(caps, "semanticTokensProvider") && caps.semanticTokensProvider != null) {
                var provider = caps.semanticTokensProvider;
                
                if (provider.legend != null) {
                    trace("✅ [LSP] Semantic tokens SUPPORTED!");
                    semanticTokensLegend = provider.legend;
                }
            } else {
                trace("⚠️ [LSP] Semantic tokens NOT supported by server");
                trace("   Available capabilities: " + haxe.Json.stringify(Reflect.fields(caps)));
            }
        }

        // ✅ ОТПРАВЛЯЕМ initialized notification
        sendNotification("initialized", {});
        
        // ✅ НОВОЕ: ОТПРАВЛЯЕМ workspace/didChangeConfiguration
        sendConfiguration();
        
        isInitialized = true;
        trace("✅ [LSP] Initialized notification sent");
    });
}

private static function sendConfiguration():Void {
    var settings:Dynamic = {
        settings: {  // ← ДОБАВИТЬ ОБЁРТКУ settings
            haxe: {
                enableCodeLens: false,
                enableDiagnostics: true,
                enableServerView: false,
                enableSignatureHelpDocumentation: true,
                diagnosticsOnFileOpen: true,
                diagnosticsForAllOpenFiles: true,
                diagnosticsPathFilter: "${workspaceRoot}",
                displayHost: null,
                displayPort: null,
                buildCompletionCache: true,
                enableCompletionCacheWarning: true,
                useLegacyCompletion: false,
                useLegacyDiagnostics: false,
                codeGeneration: {
                    functions: {
                        anonymous: {
                            argumentTypeHints: false,
                            returnTypeHint: "never",
                            useArrowSyntax: true,
                            placeOpenBraceOnNewLine: false,
                            explicitPublic: false,
                            explicitPrivate: false,
                            explicitNull: false
                        },
                        field: {
                            argumentTypeHints: true,
                            returnTypeHint: "non-void",
                            useArrowSyntax: false,
                            placeOpenBraceOnNewLine: false,
                            explicitPublic: false,
                            explicitPrivate: false,
                            explicitNull: false
                        }
                    },
                    imports: {
                        style: "type",
                        enableAutoImports: true
                    },
                    'switch': {
                        parentheses: false
                    }
                },
                exclude: ["zpp_nape"],
                postfixCompletion: {
                    level: "full"
                },
                importsSortOrder: "all-alphabetical",
                maxCompletionItems: 1000,
                renameSourceFolders: ["src", "source", "Source", "test", "tests"],
                disableRefactorCache: false,
                disableInlineValue: true,
                inlayHints: {
                    variableTypes: false,
                    parameterNames: false,
                    parameterTypes: false,
                    functionReturnTypes: false,
                    conditionals: false
                },
                serverRecording: {
                    enabled: false,
                    path: ".haxelsp/recording/",
                    exclude: [],
                    excludeUntracked: false,
                    watch: []
                }
            }
        }
    };
    
    sendNotification("workspace/didChangeConfiguration", settings);
    trace("✅ [LSP] Configuration sent");
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
                    buffer = "";  // ← ДОБАВИТЬ
                    requestId = 0;  // ← ДОБАВИТЬ
                    pendingRequests.clear();  // ← ДОБАВИТЬ
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
            }, 30000);
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
            //text: text  // включаем текст, т.к. сервер может требовать
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
    var items:Array<Dynamic> = message.params.items;
    var result:Array<Dynamic> = [];
    
    for (item in items) {
        if (item.section == "haxe") {
            result.push({
                enableCodeLens: false,
                enableDiagnostics: true,
                enableServerView: false,
                enableSignatureHelpDocumentation: true,
                diagnosticsOnFileOpen: true,
                diagnosticsForAllOpenFiles: true,
                diagnosticsPathFilter: "${workspaceRoot}",
                displayHost: null,
                displayPort: null,
                buildCompletionCache: true,
                enableCompletionCacheWarning: true,
                useLegacyCompletion: false,
                useLegacyDiagnostics: false,
                codeGeneration: {
                    functions: {
                        anonymous: {
                            argumentTypeHints: false,
                            returnTypeHint: "never",
                            useArrowSyntax: true,
                            placeOpenBraceOnNewLine: false,
                            explicitPublic: false,
                            explicitPrivate: false,
                            explicitNull: false
                        },
                        field: {
                            argumentTypeHints: true,
                            returnTypeHint: "non-void",
                            useArrowSyntax: false,
                            placeOpenBraceOnNewLine: false,
                            explicitPublic: false,
                            explicitPrivate: false,
                            explicitNull: false
                        }
                    },
                    imports: {
                        style: "type",
                        enableAutoImports: true
                    },
                    'switch': {
                        parentheses: false
                    }
                },
                exclude: ["zpp_nape"],
                postfixCompletion: {
                    level: "full"
                },
                importsSortOrder: "all-alphabetical",
                maxCompletionItems: 1000,
                renameSourceFolders: ["src", "source", "Source", "test", "tests"],
                disableRefactorCache: false,
                disableInlineValue: true,
                inlayHints: {
                    variableTypes: false,
                    parameterNames: false,
                    parameterTypes: false,
                    functionReturnTypes: false,
                    conditionals: false
                },
                serverRecording: {
                    enabled: false,
                    path: ".haxelsp/recording/",
                    exclude: [],
                    excludeUntracked: false,
                    watch: []
                }
            });
        } else {
            result.push({});
        }
    }
    
    sendResponse(message.id, result);
    trace("   ✅ Responded with configuration for " + items.length + " items");
                
            case "window/workDoneProgress/create":
                // Принимаем создание progress
                sendResponse(message.id, null);
                
            case "client/registerCapability":
                // Принимаем регистрацию capabilities
                var registrations:Array<Dynamic> = message.params.registrations;
                for (reg in registrations) {
                    registeredCapabilities.push(reg);
                    trace("   ✅ Registered capability: " + reg.method);
                }
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

    public static function getSemanticTokensLegend():Null<SemanticTokensLegend> {
        return semanticTokensLegend;
    }
}