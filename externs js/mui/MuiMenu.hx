package hide.infrastructure.external.mui;

import react.ReactComponent;
@:jsRequire("@mui/material", "Menu")
extern class MuiMenu extends ReactComponentOfProps<MuiMenuProps> {}

typedef MuiMenuProps = {
    var ?anchorEl:Dynamic;
    var ?open:Bool;
    var ?onClose:Dynamic->Void;
    var ?children:Dynamic;
    var ?className:String;
    var ?sx:Dynamic;
}
