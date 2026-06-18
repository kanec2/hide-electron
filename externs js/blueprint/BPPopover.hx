package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Popover")
extern class BPPopover extends ReactComponentOfProps<PopoverProps> {}

typedef PopoverProps = {
    var content:Dynamic;
    var children:Dynamic;
    var ?position:String; // "auto" | "top" | "bottom" | "left" | "right"
    var ?interactionKind:String; // "click" | "hover" | "hover-target"
    var ?isOpen:Bool;
    var ?onInteraction:Bool->Void;
    var ?className:String;
}
