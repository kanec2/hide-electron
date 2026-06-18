package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "ButtonGroup")
extern class BPButtonGroup extends ReactComponentOfProps<ButtonGroupProps> {}

typedef ButtonGroupProps = {
    var children:Dynamic;
    var ?vertical:Bool;
    var ?minimal:Bool;
    var ?large:Bool;
    var ?fill:Bool;
    var ?className:String;
}