package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Toaster")
extern class BPToaster {
    public static function create(?props:Dynamic, ?container:js.html.Element):ToasterInstance;
}

extern class ToasterInstance {
    public function show(props:ToastProps, ?key:String):String;
    public function dismiss(key:String):Void;
    public function clear():Void;
    public function getToasts():Array<ToastProps>;
}

typedef ToastProps = {
    var message:Dynamic;
    var ?intent:String;
    var ?icon:String;
    var ?timeout:Int;
    var ?action:Dynamic;
    var ?onDismiss:String->Bool->Void;
    var ?className:String;
}