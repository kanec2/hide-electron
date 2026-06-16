package hide.infrastructure;

import hide.domain.services.IDomAccess;
import hx.injection.Service;

class BrowserDomAccess implements IDomAccess implements Service {
    public function new() {}
    
    public function getElementById(id:String):Dynamic {
        return js.Browser.document.getElementById(id);
    }
    
    public function addWindowEventListener(event:String, handler:Dynamic->Void):Void {
        js.Browser.window.addEventListener(event, handler);
    }
    
    public function removeWindowEventListener(event:String, handler:Dynamic->Void):Void {
        js.Browser.window.removeEventListener(event, handler);
    }
}