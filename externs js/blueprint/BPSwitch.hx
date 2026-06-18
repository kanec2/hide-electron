package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Switch")
extern class BPSwitch extends ReactComponentOfProps<SwitchProps> {}

typedef SwitchProps = {
    var ?checked:Bool;
    var ?defaultChecked:Bool;
    var ?label:String;
    var ?onChange:Dynamic->Void;
    var ?disabled:Bool;
    @:native("inline") var ?inlineMode:Bool;
    var ?innerLabel:String;
    var ?innerLabelChecked:String;
    var ?className:String;
}