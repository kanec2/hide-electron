package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Checkbox")
extern class MuiCheckbox extends ReactComponentOfProps<MuiCheckboxProps> {}

typedef MuiCheckboxProps = {
    var ?checked:Bool;
    var ?defaultChecked:Bool;
    var ?onChange:Dynamic->Void;
    var ?disabled:Bool;
    var ?color:String;
    var ?size:String;
    var ?className:String;
    var ?sx:Dynamic;
}