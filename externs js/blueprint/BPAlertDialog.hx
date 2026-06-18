package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "AlertDialog")
extern class BPAlertDialog extends ReactComponentOfProps<AlertDialogProps> {}

typedef AlertDialogProps = {
    var isOpen:Bool;
    var ?onConfirm:Dynamic->Void;
    var ?onCancel:Dynamic->Void;
    var ?confirmButtonText:String;
    var ?cancelButtonText:String;
    var ?intent:String;
    var ?icon:String;
    var ?className:String;
    var children:Dynamic;
}