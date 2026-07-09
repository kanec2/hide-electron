package hide.infrastructure.external;


import js.html.Element;

/**
Адаптер для Monaco Editor.
Инкапсулирует работу с Monaco Editor API.
*/
class MonacoEditorAdapter {
    public var editor:Dynamic;
    private var container:Element;
    private var monaco:Dynamic;
    
    public function new(container:Element) {
        this.container = container;
        initMonaco();
    }
    
    private function initMonaco():Void {
        monaco = untyped require('monaco-editor');
        
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
        
        trace("✅ [MonacoEditor] Editor initialized");
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
}