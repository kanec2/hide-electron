package hide.domain.services;

import hx.injection.Service;
interface IClipboardService extends Service {
    function getText():String;
    function setText(text:String):Void;
}