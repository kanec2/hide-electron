package hide.domain.valueobjects;

typedef LayoutConfig = {
    var type:String;
    var componentName:Null<String>;
    var componentState:Null<Dynamic>;
    var content:Array<LayoutConfig>;
    var id:Null<String>;
    var width:Null<Int>;
    var height:Null<Int>;
}