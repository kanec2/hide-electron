package hide.application.services;

import hide.domain.services.IClipboardService;
import hx.injection.Service;
class ClipboardService implements Service {
    private var clipboard:IClipboardService;
    public function new(clipboard:IClipboardService) {
        this.clipboard = clipboard;
    }

    public function copy(text:String):Void {
        clipboard.setText(text);
    }

    public function paste():String {
        return clipboard.getText();
    }
}