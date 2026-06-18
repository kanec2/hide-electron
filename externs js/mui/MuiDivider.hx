package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Divider")
extern class MuiDivider extends ReactComponentOfProps<MuiDividerProps> {}

typedef MuiDividerProps = {
    var ?orientation:String; // "horizontal" | "vertical"
    var ?variant:String; // "fullWidth" | "inset" | "middle"
    var ?className:String;
    var ?sx:Dynamic;
}