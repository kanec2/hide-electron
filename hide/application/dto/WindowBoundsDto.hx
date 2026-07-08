package hide.application.dto;

typedef WindowBoundsDto = {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var ?isMaximized:Bool;
    var ?isFullscreen:Bool;
}