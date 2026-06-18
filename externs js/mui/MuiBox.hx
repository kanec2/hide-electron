package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Box")
extern class MuiBox extends ReactComponentOfProps<MuiBoxProps> {}

typedef MuiBoxProps = {
    var ?children:Dynamic;
    var ?className:String;
    var ?sx:Dynamic;
    var ?component:Dynamic;
}