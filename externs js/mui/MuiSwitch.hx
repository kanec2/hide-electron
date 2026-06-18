package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Switch")
extern class MuiSwitch extends ReactComponentOfProps<MuiSwitchProps> {}

typedef MuiSwitchProps = {
    var ?checked:Bool;
    var ?defaultChecked:Bool;
    var ?onChange:Dynamic->Void;
    var ?disabled:Bool;
    var ?color:String;
    var ?size:String; // "small" | "medium"
    var ?className:String;
    var ?sx:Dynamic;
}