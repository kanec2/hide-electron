package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Tabs")
extern class BPTabs extends ReactComponentOfProps<TabsProps> {}

typedef TabsProps = {
    var ?id:String;
    var ?selectedTabId:String;
    var ?onChange:String->String->Dynamic->Void;
    var ?vertical:Bool;
    var ?large:Bool;
    var ?animate:Bool;
    var ?className:String;
    var children:Dynamic;
}