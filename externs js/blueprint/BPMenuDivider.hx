package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "MenuDivider")
extern class BPMenuDivider extends ReactComponentOfProps<MenuDividerProps> {}

typedef MenuDividerProps = {
    var ?title:String;
    var ?className:String;
}