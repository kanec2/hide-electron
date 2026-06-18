package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "ContextMenu")
extern class BPContextMenu extends ReactComponentOfProps<ContextMenuProps> {}

typedef ContextMenuProps = {
    var content:Dynamic;
    var ?className:String;
}
