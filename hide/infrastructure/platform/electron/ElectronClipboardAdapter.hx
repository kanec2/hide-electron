package hide.infrastructure.platform.electron;

import hide.domain.services.IClipboardService;
import hx.injection.Service;
class ElectronClipboardAdapter implements IClipboardService implements Service {
    public function new() {}
    public function getText():String {
        // TODO: Реализовать через electron.clipboard
        return "";
    }

    public function setText(text:String):Void {
        // TODO: Реализовать через electron.clipboard
    }
}