package hide.domain.valueobjects;

typedef LayoutState = {
    var content:Array<LayoutConfig>;
    var fullScreen:Null<{component:String, state:Dynamic}>;
}