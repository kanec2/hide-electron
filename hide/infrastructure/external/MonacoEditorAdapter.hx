package hide.infrastructure.external;


import js.html.Element;
import hide.infrastructure.external.monaco.Model;
import hide.infrastructure.external.monaco.Position;
import hide.infrastructure.external.monaco.*;
import hide.domain.services.CompletionItem;
import js.node.Path;  // ← ДОБАВИТЬ
import js.node.Fs;    // ← ДОБАВИТЬ
import tink.core.*;
using tink.CoreApi;
/**
Адаптер для Monaco Editor.
Инкапсулирует работу с Monaco Editor API.
*/
class MonacoEditorAdapter {
    public var editor:Dynamic;
    private var container:Element;
    private var monaco:Dynamic;
    
    private var lspService:Null<hide.domain.services.ILanguageServer>;
    private var currentUri:String;
    private var documentVersion:Int = 0;

    public function new(container:Element) {
        this.container = container;
        initMonaco();
    }
    
    private function initMonaco():Void {
        trace("🎬 [MonacoEditor] Initializing Monaco Editor...");
        // ✅ Пытаемся получить Monaco из глобальной области (если загружен через AMD)
        monaco = untyped js.Browser.window.monaco;
        
        // Если не найден, пробуем Node.js require
        if (monaco == null) {
            monaco = untyped require('monaco-editor');
        }
        
        if (monaco == null) {
            trace("❌ [MonacoEditor] Monaco not loaded!");
            return;
        }
        
        // ✅ Настраиваем worker'ы для Electron
        untyped monaco.environment = untyped monaco.environment != null ? monaco.environment : {};
        untyped monaco.environment.getWorkerUrl = function(workerId:String, label:String):String {
            // Возвращаем пустую строку или правильный путь к worker'ам
            return '';
        };
        
        trace("📦 [MonacoEditor] Monaco Editor required successfully");
        trace("📦 [MonacoEditor] Monaco version: " + (monaco.editor ? "has editor API" : "NO editor API"));
        // ✅ Загружаем конфигурацию Haxe из JSON
        registerHaxeLanguage();
        // ✅ Инициализируем TextMate Grammar ПЕРЕД созданием редактора
        //hide.infrastructure.external.monaco.TextMateInitializer.initialize(monaco);

        // Небольшая задержка чтобы grammar успел загрузиться
        haxe.Timer.delay(function() {
            trace("🎨 [MonacoEditor] Creating editor instance...");
            editor = monaco.editor.create(container, {
                value: "// Welcome to HIDE IDE\n",
                language: "haxe",
                theme: "vs-dark",
                automaticLayout: true,
                minimap: { enabled: true },
                fontSize: 14,
                lineNumbers: "on",
                scrollBeyondLastLine: true,
                renderWhitespace: "selection",
                wordWrap: "off",
                tabSize: 4,
                insertSpaces: true,
                formatOnPaste: true,
                formatOnType: true
            });
            
            trace("✅ [MonacoEditor] Editor created successfully");
            trace("🔍 [MonacoEditor] Editor language: " + editor.getModel().getLanguageId());
            trace("🔍 [MonacoEditor] Editor value length: " + editor.getValue().length);
        }, 200);
        
        trace("✅ [MonacoEditor] Editor initialized");
    }

    private function registerHaxeLanguage():Void {
        // ✅ Загружаем JSON через fetch (работает в renderer)
        /*
        untyped fetch("assets/grammars/haxe-monarch.json")
            .then(function(response) {
                return response.json();
            })
            .then(function(grammar) {
                // Регистрируем язык
                // Устанавливаем токенизатор
                monaco.languages.setMonarchTokensProvider('haxe', grammar);
                trace("✅ [MonacoEditor] Haxe Monarch grammar loaded");
            })
            .catchError(function(err) {
                trace("❌ [MonacoEditor] Failed to load Haxe grammar: " + err);
            });*/
        var grammar = untyped window.haxeGrammar;
        // Проверяем что grammar не пустой
        if (grammar == null) {
            trace("❌ [MonacoEditor] Grammar is NULL!");
            return;
        }
        
        if (!Reflect.hasField(grammar, "tokenizer")) {
            trace("❌ [MonacoEditor] Grammar has no tokenizer field!");
            return;
        }

        // ✅ Минимальная регистрация языка Haxe (без Monarch)
        var languages:Array<Dynamic> = monaco.languages.getLanguages();
        var haxeExists = false;
        for (lang in languages) {
            if (lang.id == 'haxe') {
                haxeExists = true;
                break;
            }
        }
        
        if (!haxeExists) {
            untyped monaco.languages.register({ id: 'haxe' });
            trace("✅ [MonacoEditor] Haxe language registered");
        }

        if (grammar == null) {
            trace("⚠️ [MonacoEditor] Grammar not loaded yet, using default");
            return;
        }
        // Устанавливаем токенизатор
        trace(" [MonacoEditor] Setting Monarch tokens provider...");
        monaco.languages.setMonarchTokensProvider('haxe', grammar);
        trace("✅ [MonacoEditor] Haxe Monarch grammar loaded and applied");
        
    }

    public function setValue(value:String):Void {
        if (editor != null) {
            editor.setValue(value);
        }
    }
    
    public function getValue():String {
        if (editor != null) {
            return editor.getValue();
        }
        return "";
    }
    
    public function setLanguage(language:String):Void {
        if (editor != null) {
            var model = editor.getModel();
            if (model != null) {
                monaco.editor.setModelLanguage(model, language);
            }
        }
    }
    
    public function getLanguage():String {
        if (editor != null) {
            var model = editor.getModel();
            if (model != null) {
                return model.getLanguageId();
            }
        }
        return "plaintext";
    }
    
    public function getModel():Dynamic {
        if (editor != null) {
            return editor.getModel();
        }
        return null;
    }
    
    public function focus():Void {
        if (editor != null) {
            editor.focus();
        }
    }
    
    public function dispose():Void {
        if (editor != null) {
            editor.dispose();
            editor = null;
        }
    }
    
    public function onDidChangeModelContent(callback:Dynamic->Void):Void {
        if (editor != null) {
            editor.onDidChangeModelContent(callback);
        }
    }
    
    public function getPosition():{line:Int, column:Int} {
        if (editor != null) {
            var pos = editor.getPosition();
            return { line: pos.lineNumber, column: pos.column };
        }
        return { line: 1, column: 1 };
    }
    
    public function setPosition(line:Int, column:Int):Void {
        if (editor != null) {
            editor.setPosition({ lineNumber: line, column: column });
            editor.revealLineInCenter(line);
        }
    }
    
    public function setTheme(theme:String):Void {
        monaco.editor.setTheme(theme);
    }
    
    public function updateOptions(options:Dynamic):Void {
        if (editor != null) {
            editor.updateOptions(options);
        }
    }
    public function setLanguageServer(lsp:hide.domain.services.ILanguageServer):Void {
        this.lspService = lsp;
        registerCompletionProvider();
        registerHoverProvider();
        registerDefinitionProvider();
        registerSemanticTokensProvider();  // ← НОВОЕ
        
        lsp.onDiagnostics(function(uri, diagnostics) {
            updateDiagnostics(uri, diagnostics);
        });
        trace("✅ [MonacoEditor] LSP providers registered");
    }

    public function setCurrentFile(path:String):Void {
        // ✅ Конвертируем путь в file:// URI
        var normalizedPath = path.split("\\").join("/");
        if (normalizedPath.charAt(0) != "/") {
            normalizedPath = "/" + normalizedPath;
        }
        currentUri = "file://" + normalizedPath;
        
        // ✅ Создаем модель с правильным URI
        var model = monaco.editor.getModel(untyped js.Lib.nativeThis.monaco.Uri.parse(currentUri));
        if (model == null) {
            var content = editor.getValue();
            var language = getLanguage();
            model = monaco.editor.createModel(content, language, untyped js.Lib.nativeThis.monaco.Uri.parse(currentUri));
            editor.setModel(model);
        }
        
        documentVersion = 1;
        
        if (lspService != null) {
            lspService.didOpen(currentUri, getLanguage(), documentVersion, editor.getValue());
            trace("📂 [MonacoEditor] File opened: " + currentUri);
        }
    }

    // ✅ ИСПРАВЛЕНО: все три провайдера возвращают Promise
    private function registerCompletionProvider():Void {
        if (lspService == null) return;
        monaco.languages.registerCompletionItemProvider('haxe', {
            triggerCharacters: ['.', ':'],
            provideCompletionItems: function(model:Model, position:Position, token:Any, context:Dynamic) {
                var uri = model.uri.toString();
                var line = position.lineNumber - 1;
                var character = position.column - 1;
                
                // ✅ Возвращаем Promise, а не Future
                return new js.lib.Promise(function(resolve, reject) {
                    lspService.completion(uri, line, character).handle(function(items) {
                        var suggestions = [];
                        if (items != null) {
                            for (item in items) {
                                suggestions.push({
                                    label: item.label,
                                    kind: mapCompletionKind(item.kind),
                                    insertText: item.insertText != null ? item.insertText : item.label,
                                    detail: item.detail,
                                    documentation: item.documentation != null 
                                        ? { value: item.documentation } 
                                        : null,
                                    range: new Range(
                                        position.lineNumber, position.column,
                                        position.lineNumber, position.column
                                    )
                                });
                            }
                        }
                        resolve({ suggestions: suggestions });
                    });
                });
            }
        });
    }

    private function registerHoverProvider():Void {
        if (lspService == null) return;
        
        monaco.languages.registerHoverProvider('haxe', {
            provideHover: function(model:Model, position:Position, token:Any) {
                var uri = model.uri.toString();
                var line = position.lineNumber - 1;
                var character = position.column - 1;
                
                // ✅ ИСПРАВЛЕНО: оборачиваем в Promise
                return new js.lib.Promise(function(resolve, reject) {
                    lspService.hover(uri, line, character).handle(function(info) {
                        if (info == null) {
                            resolve(null);
                            return;
                        }
                        resolve({
                            contents: [{ value: info.contents }],
                            range: info.range != null ? new Range(
                                info.range.start.line + 1,
                                info.range.start.character + 1,
                                info.range.end.line + 1,
                                info.range.end.character + 1
                            ) : null
                        });
                    });
                });
            }
        });
    }

    private function registerDefinitionProvider():Void {
        if (lspService == null) return;
        
        monaco.languages.registerDefinitionProvider('haxe', {
            provideDefinition: function(model:Model, position:Position, token:Any) {
                var uri = model.uri.toString();
                var line = position.lineNumber - 1;
                var character = position.column - 1;
                
                // ✅ ИСПРАВЛЕНО: оборачиваем в Promise
                return new js.lib.Promise(function(resolve, reject) {
                    lspService.definition(uri, line, character).handle(function(location) {
                        if (location == null) {
                            resolve(null);
                            return;
                        }
                        resolve({
                            uri: location.uri,
                            range: new Range(
                                location.range.start.line + 1,
                                location.range.start.character + 1,
                                location.range.end.line + 1,
                                location.range.end.character + 1
                            )
                        });
                    });
                });
            }
        });
    }

    private function registerSemanticTokensProvider():Void {
        if (lspService == null) return;
        
        // Сначала получаем legend
        lspService.semanticTokensLegend().handle(function(legend) {
            if (legend == null) {
                trace("⚠️ [MonacoEditor] Semantic tokens not supported by server");
                return;
            }
            
            trace("✅ [MonacoEditor] Registering semantic tokens provider");
            
            // Регистрируем провайдер
            monaco.languages.registerDocumentSemanticTokensProvider('haxe', {
                getLegend: function() {
                    return legend;
                },
                provideDocumentSemanticTokens: function(model, lastResultId, token) {
                    var uri = model.uri.toString();
                    return lspService.semanticTokensFull(uri).map(function(result) {
                        if (result == null) return null;
                        return {
                            data: result.data,
                            resultId: result.resultId
                        };
                    });
                },
                releaseDocumentSemanticTokens: function(resultId) {
                    // Можно кэшировать результаты
                }
            });
        });
    }

    private function mapCompletionKind(lspKind:Int):Int {
        return switch (lspKind) {
            case 1: 1;   // Text
            case 2: 1;   // Method
            case 3: 1;   // Function
            case 4: 4;   // Field
            case 5: 5;   // Variable
            case 6: 6;   // Class
            case 7: 8;   // Interface
            case 8: 9;   // Module
            case 9: 10;  // Property
            case 10: 13; // Keyword
            default: 0;
        };
    }

    private function updateDiagnostics(uri:String, diagnostics:Array<Dynamic>):Void {
        var model = editor.getModel();
        if (model == null) return;
        
        var markers = [];
        for (diag in diagnostics) {
            markers.push({
                severity: mapSeverity(diag.severity),
                message: diag.message,
                startLineNumber: diag.range.start.line + 1,
                startColumn: diag.range.start.character + 1,
                endLineNumber: diag.range.end.line + 1,
                endColumn: diag.range.end.character + 1
            });
        }
        
        monaco.editor.setModelMarkers(model, "haxe", markers);
    }

    private function mapSeverity(lspSeverity:Int):Int {
        return switch (lspSeverity) {
            case 1: 8; // Error
            case 2: 4; // Warning
            case 3: 2; // Information
            case 4: 1; // Hint
            default: 1;
        };
    }

    // В методе onContentChanged добавляем уведомление LSP
    public function onContentChanged(callback:Void->Void):Void {
        editor.onDidChangeModelContent(function(_) {
            callback();
            
            // Уведомляем LSP об изменении
            if (lspService != null && currentUri != null) {
                documentVersion++;
                var content = editor.getValue();
                lspService.didChange(currentUri, documentVersion, content);
            }
        });
    }
}