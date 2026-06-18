package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Tab")
extern class BPTab extends ReactComponentOfProps<TabProps> {}

typedef TabProps = {
    var id:String;
    var ?title:Dynamic;
    var ?icon:String;
    var ?disabled:Bool;
    var ?panel:Dynamic;
    var ?className:String;
    var children:Dynamic;
}