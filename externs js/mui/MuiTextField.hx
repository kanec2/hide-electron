package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "TextField")
extern class MuiTextField extends ReactComponentOfProps<MuiTextFieldProps> {}

typedef MuiTextFieldProps = {
    var ?value:Dynamic;
    var ?defaultValue:Dynamic;
    var ?label:String;
    var ?placeholder:String;
    var ?variant:String; // "outlined" | "filled" | "standard"
    var ?size:String; // "small" | "medium"
    var ?type:String;
    var ?fullWidth:Bool;
    var ?disabled:Bool;
    var ?onChange:Dynamic->Void;
    var ?onBlur:Dynamic->Void;
    var ?className:String;
    var ?sx:Dynamic;
}