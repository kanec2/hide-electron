package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "ButtonGroup")
extern class MuiButtonGroup extends ReactComponentOfProps<MuiButtonGroupProps> {}

typedef MuiButtonGroupProps = {
    var ?children:Dynamic;
    var ?variant:String;
    var ?color:String;
    var ?size:String;
    var ?orientation:String; // "horizontal" | "vertical"
    var ?disabled:Bool;
    var ?fullWidth:Bool;
    var ?className:String;
    var ?sx:Dynamic;
}