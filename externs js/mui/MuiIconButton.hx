package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "IconButton")
extern class MuiIconButton extends ReactComponentOfProps<MuiIconButtonProps> {}

typedef MuiIconButtonProps = {
    var ?children:Dynamic;
    var ?color:String;
    var ?size:String;
    var ?disabled:Bool;
    var ?onClick:Dynamic->Void;
    var ?className:String;
    var ?sx:Dynamic;
}