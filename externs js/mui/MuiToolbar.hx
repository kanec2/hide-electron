package hide.infrastructure.external.mui;

import react.ReactComponent;
@:jsRequire("@mui/material", "Toolbar")
extern class MuiToolbar extends ReactComponentOfProps<MuiToolbarProps> {}

typedef MuiToolbarProps = {
    var ?children:Dynamic;
    var ?variant:String; // "regular" | "dense"
    var ?disableGutters:Bool;
    var ?className:String;
    var ?sx:Dynamic;
}
