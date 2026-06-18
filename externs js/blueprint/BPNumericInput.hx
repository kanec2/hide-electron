package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "NumericInput")
extern class BPNumericInput extends ReactComponentOfProps<NumericInputProps> {}

typedef NumericInputProps = {
    var ?value:Float;
    var ?defaultValue:Float;
    var ?min:Float;
    var ?max:Float;
    var ?stepSize:Float;
    var ?onValueChange:Float->Void;
    var ?fill:Bool;
    var ?small:Bool;
    var ?large:Bool;
    var ?disabled:Bool;
    var ?className:String;
}