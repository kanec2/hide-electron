package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Icon")
extern class BPIcon extends ReactComponentOfProps<IconProps> {}

typedef IconProps = {
    var icon:String;
    var ?intent:String;
    var ?iconSize:Int;
    var ?className:String;
}
