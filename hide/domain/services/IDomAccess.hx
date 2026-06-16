package hide.domain.services;

import hx.injection.Service;

interface IDomAccess extends Service {
    function getElementById(id:String):Dynamic;
    function addWindowEventListener(event:String, handler:Dynamic->Void):Void;
    function removeWindowEventListener(event:String, handler:Dynamic->Void):Void;
}