package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Menu")
extern class BPMenu extends ReactComponentOfProps<MenuProps> {}

typedef MenuProps = {
    var children:Dynamic;
    var ?className:String;
    var ?large:Bool;
}