package hide.infrastructure.external.blueprint;
import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "HTMLSelect")
extern class BPHTMLSelect extends ReactComponentOfProps<HTMLSelectProps> {}

typedef HTMLSelectProps = {
    var ?value:String;
    var ?defaultValue:String;
    var ?options:Array<Dynamic>;
    var ?onChange:Dynamic->Void;
    var ?fill:Bool;
    var ?large:Bool;
    var ?small:Bool;
    var ?disabled:Bool;
    var ?className:String;
}