package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "CardContent")
extern class MuiCardContent extends ReactComponentOfProps<MuiCardContentProps> {}

typedef MuiCardContentProps = {
    var ?children:Dynamic;
    var ?className:String;
    var ?sx:Dynamic;
}