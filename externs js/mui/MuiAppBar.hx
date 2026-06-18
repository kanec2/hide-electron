package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "AppBar")
extern class MuiAppBar extends ReactComponentOfProps<MuiAppBarProps> {}

typedef MuiAppBarProps = {
    var ?children:Dynamic;
    var ?position:String; // "fixed" | "absolute" | "sticky" | "static" | "relative"
    var ?color:String;
    var ?className:String;
    var ?sx:Dynamic;
}