package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Dialog")
extern class BPDialog extends ReactComponentOfProps<DialogProps> {}

typedef DialogProps = {
    var isOpen:Bool;
    var ?onClose:Dynamic->Void;
    var ?title:String;
    var ?icon:String;
    var ?className:String;
    var ?canOutsideClickClose:Bool;
    var ?canEscapeKeyClose:Bool;
    var ?isCloseButtonShown:Bool;
    var ?style:Dynamic;
    var children:Dynamic;
}