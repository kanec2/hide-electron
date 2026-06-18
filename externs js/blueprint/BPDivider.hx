package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Divider")
extern class BPDivider extends ReactComponentOfProps<DividerProps> {}

typedef DividerProps = {
    var ?className:String;
}