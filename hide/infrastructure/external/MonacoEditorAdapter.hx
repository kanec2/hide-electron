package hide.infrastructure.external;

import hide.domain.services.IElement;
import js.html.Element;
import monaco.ScriptEditor;
import monaco.Model;
import monaco.Languages;
import monaco.CompletionItem;
import monaco.CompletionItemKind;
import monaco.CompletionItemInsertTextRule;
import monaco.CompletionProvider;
import monaco.Range;
import monaco.Position;

/**
Адаптер для Monaco Editor.
Оборачивает Monaco в IElement для интеграции с DI.
*/
class MonacoEditorAdapter implements IElement {
    private var element:Element;
    private var editor:ScriptEditor;
    private var monaco:Dynamic; // Для методов, которых нет в externs (register, setMonarchTokensProvider)

    public function new(element:Element) {
        this.element = element;
        initMonaco();
    }

    private function initMonaco():Void {
        monaco = untyped require('monaco-editor');
        
        // Используем типизированный ScriptEditor.create
        editor = ScriptEditor.create(element, {
            value: "// HIDE IDE Script Editor\n",
            language: 'haxe',
            theme: 'vs-dark',
            automaticLayout: true,
            fontSize: 14,
            minimap: { enabled: true },
            scrollBeyondLastLine: true,
            renderWhitespace: 'selection',
            bracketPairColorization: { enabled: true },
            guides: {
                bracketPairs: true,
                indentation: true
            }
        });
        
        registerHaxeLanguage();
    }

    private function registerHaxeLanguage():Void {
        var languages:Array<Dynamic> = monaco.languages.getLanguages();
        var haxeExists = false;
        for (lang in languages) {
            if (lang.id == 'haxe') {
                haxeExists = true;
                break;
            }
        }
        
        
            
            // Используем типизированный CompletionProvider
            Languages.registerCompletionItemProvider('haxe', {
                provideCompletionItems: function(model:Model, position:Position, token:Any, context:Dynamic) {
                    var word = untyped model.getWordUntilPosition(position);
                    var range = new Range(
                        position.lineNumber, word.startColumn,
                        position.lineNumber, word.endColumn
                    );
                    
                    return {
                        suggestions: [
                            {
                                label: 'trace',
                                kind: CompletionItemKind.Function,
                                insertText: 'trace(${1:message});',
                                insertTextRules: CompletionItemInsertTextRule.InsertAsSnippet,
                                documentation: { value: 'Выводит сообщение в консоль' },
                                range: range
                            },
                            {
                                label: 'function',
                                kind: CompletionItemKind.Keyword,
                                insertText: 'function ${1:name}(${2:params}):${3:Void} {\n\t$0\n}',
                                insertTextRules: CompletionItemInsertTextRule.InsertAsSnippet,
                                documentation: { value: 'Объявление функции' },
                                range: range
                            },
                            {
                                label: 'class',
                                kind: CompletionItemKind.Keyword,
                                insertText: 'class ${1:ClassName} {\n\tpublic function new() {\n\t\t$0\n\t}\n}',
                                insertTextRules: CompletionItemInsertTextRule.InsertAsSnippet,
                                documentation: { value: 'Объявление класса' },
                                range: range
                            }
                        ]
                    };
                }
            });
        }
    }

    // === Реализация IElement ===

    public function setInnerHtml(html:String):Void {}

    public function appendChild(child:IElement):Void {}

    public function addEventListener(event:String, handler:Dynamic->Void):Void {
        element.addEventListener(event, handler);
    }

    public function getParent():Null<IElement> {
        if (element.parentElement == null) return null;
        return new HtmlElement(element.parentElement);
    }

    // === Monaco-specific методы (типизированные) ===

    public function getValue():String {
        return editor.getValue();
    }

    public function setValue(content:String):Void {
        editor.setValue(content);
    }

    public function getLanguage():String {
        var model = editor.getModel();
        return untyped model.getLanguageId();
    }

    public function setLanguage(language:String):Void {
        var model = editor.getModel();
        if (model != null) {
            untyped monaco.editor.setModelLanguage(model, language);
        }
    }

    public function focus():Void {
        editor.focus();
    }

    public function dispose():Void {
        if (editor != null) {
            editor.dispose();
            editor = null;
        }
    }
    
    // === Дополнительные методы из externs ===
    
    public function onContentChanged(callback:Void->Void):Void {
        editor.onDidChangeModelContent(callback);
    }
    
    public function addCommand(keyCode:Int, callback:Void->Void):Void {
        editor.addCommand(keyCode, callback);
    }
}