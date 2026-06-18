package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Button")
extern class BPButton extends ReactComponentOfProps<ButtonProps> {}

typedef ButtonProps = {
    var text:String;
    var ?icon:String;
    var ?intent:String; // "primary" | "success" | "warning" | "danger"
    var ?onClick:Dynamic->Void;
    var ?disabled:Bool;
    var ?className:String;
    var ?minimal:Bool;
    var ?small:Bool;
    var ?large:Bool;
    var ?fill:Bool;
}