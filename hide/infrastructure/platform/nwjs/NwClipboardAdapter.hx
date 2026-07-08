package hide.infrastructure.platform.electron.nwjs;

import hide.domain.services.IClipboardService;
import hx.injection.Service;
class NwClipboardAdapter implements IClipboardService implements Service {
    public function new() {}
    public function getText():String {
        // TODO: Реализовать через nw.Clipboard
        return "";
    }

    public function setText(text:String):Void {
        // TODO: Реализовать через nw.Clipboard
    }
}