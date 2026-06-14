package hide.presentation.ui;

class StatusBar {
    private var element:Dynamic;
    
    public function new(element:Dynamic) {
        this.element = element;
    }
    
    public function showMessage(msg:String):Void {
        trace("[StatusBar] " + msg);
    }
    
    public function setError(msg:String):Void {
        trace("[StatusBar ERROR] " + msg);
    }
}