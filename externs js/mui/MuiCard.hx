package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Card")
extern class MuiCard extends ReactComponentOfProps<MuiCardProps> {}

typedef MuiCardProps = {
    var ?children:Dynamic;
    var ?variant:String; // "elevation" | "outlined"
    var ?elevation:Int;
    var ?className:String;
    var ?sx:Dynamic;
}