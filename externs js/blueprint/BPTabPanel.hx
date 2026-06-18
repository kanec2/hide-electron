package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "TabPanel")
extern class TabPanel extends ReactComponentOfProps<TabPanelProps> {}

typedef TabPanelProps = {
    var children:Dynamic;
    var ?className:String;
}