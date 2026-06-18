package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "TabList")
extern class BPTabList extends ReactComponentOfProps<TabListProps> {}

typedef TabListProps = {
    var children:Dynamic;
    var ?className:String;
}