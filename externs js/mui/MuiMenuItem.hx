package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "MenuItem")
extern class MuiMenuItem extends ReactComponentOfProps<MuiMenuItemProps> {}

typedef MuiMenuItemProps = {
    var ?children:Dynamic;
    var ?disabled:Bool;
    var ?selected:Bool;
    var ?onClick:Dynamic->Void;
    var ?className:String;
    var ?sx:Dynamic;
}