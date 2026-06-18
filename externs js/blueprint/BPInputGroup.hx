package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "InputGroup")
extern class BPInputGroup extends ReactComponentOfProps<InputGroupProps> {}

typedef InputGroupProps = {
    var ?value:String;
    var ?defaultValue:String;
    var ?placeholder:String;
    var ?leftIcon:String;
    var ?rightElement:Dynamic;
    var ?onChange:Dynamic->Void;
    var ?onBlur:Dynamic->Void;
    var ?fill:Bool;
    var ?large:Bool;
    var ?small:Bool;
    var ?disabled:Bool;
    var ?className:String;
}