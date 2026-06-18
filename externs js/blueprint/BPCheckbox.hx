package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Checkbox")
extern class BPCheckbox extends ReactComponentOfProps<CheckboxProps> {}

typedef CheckboxProps = {
    var ?checked:Bool;
    var ?defaultChecked:Bool;
    var ?label:String;
    var ?onChange:Dynamic->Void;
    var ?disabled:Bool;
    @:native("inline") var ?inlineMode:Bool;
    var ?className:String;
}