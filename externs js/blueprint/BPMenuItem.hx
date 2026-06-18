package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "MenuItem")
extern class BPMenuItem extends ReactComponentOfProps<MenuItemProps> {}

typedef MenuItemProps = {
    var text:String;
    var ?icon:String;
    var ?intent:String;
    var ?onClick:Dynamic->Void;
    var ?disabled:Bool;
    var ?submenu:Dynamic;
    var ?label:String;
    var ?labelElement:Dynamic;
    var ?multiline:Bool;
    var ?shouldDismissPopover:Bool;
    var ?className:String;
}
