package hide.infrastructure.external.monaco;

extern class Model {
	var uri: Dynamic;  // ← ДОБАВИТЬ (Monaco URI объект)
    function updateOptions( opts : {?insertSpaces:Bool,?tabSize:Int,?trimAutoWhitespace:Bool} ) : Void;
    function getValueInRange( pos : { startLineNumber : Int, startColumn : Int, endLineNumber : Int, endColumn : Int } ) : String;
    function getLanguageId(): String;  // ← ДОБАВИТЬ (используется в getLanguage())
}