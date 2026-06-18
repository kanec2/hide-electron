package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Button")
extern class MuiButton extends ReactComponentOfProps<MuiButtonProps> {}

typedef MuiButtonProps = {
    var ?children:Dynamic;
    var ?variant:String; // "text" | "contained" | "outlined"
    var ?color:String; // "inherit" | "primary" | "secondary" | "success" | "error" | "info" | "warning"
    var ?size:String; // "small" | "medium" | "large"
    var ?disabled:Bool;
    var ?onClick:Dynamic->Void;
    var ?startIcon:Dynamic;
    var ?endIcon:Dynamic;
    var ?fullWidth:Bool;
    var ?className:String;
    var ?sx:Dynamic;
}
