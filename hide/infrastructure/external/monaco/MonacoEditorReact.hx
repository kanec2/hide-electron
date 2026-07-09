package hide.infrastructure.external.monaco;

// infrastructure/external/monaco/MonacoEditorReact.hx
package hide.infrastructure.external.monaco;

import react.ReactComponent;

@:jsRequire("@huyhuy/monaco-editor-react-electron")
extern class MonacoEditorReact extends ReactComponentOfProps<MonacoEditorProps> {
}

typedef MonacoEditorProps = {
    var ?defaultValue:String;
    var ?defaultLanguage:String;
    var ?defaultPath:String;
    var ?value:String;
    var ?language:String;
    var ?path:String;
    var ?theme:String;  // "vs-dark" | "light"
    var ?line:Int;
    var ?loading:Dynamic;  // React Node
    var ?options:Dynamic;  // IStandaloneEditorConstructionOptions
    var ?saveViewState:Bool;
    var ?keepCurrentModel:Bool;
    var ?width:Dynamic;  // Int | String
    var ?height:Dynamic; // Int | String
    var ?className:String;
    var ?wrapperProps:Dynamic;
    var ?beforeMount:Dynamic->Void;  // (monaco) -> Void
    var ?onMount:Dynamic->Dynamic->Void;  // (editor, monaco) -> Void
    var ?onChange:Dynamic->Dynamic->Void;  // (value, event) -> Void
    var ?onValidate:Dynamic->Void;  // (markers) -> Void
}

// Экспорт loader для конфигурации
@:jsRequire("@huyhuy/monaco-editor-react-electron", "loader")
extern class MonacoLoader {
    static function config(cfg:Dynamic):Void;
    static function init():js.lib.Promise<Dynamic>;
}