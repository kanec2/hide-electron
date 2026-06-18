package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Card")
extern class BPCard extends ReactComponentOfProps<CardProps> {}

typedef CardProps = {
    var children:Dynamic;
    var ?elevation:Int; // 0 | 1 | 2 | 3 | 4
    var ?interactive:Bool;
    var ?className:String;
}