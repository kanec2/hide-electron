package hide.infrastructure.platform.electron;

import hide.domain.services.IShortcutService;
import hx.injection.Service;
class ElectronShortcutAdapter implements IShortcutService implements Service {
    public function new() {}
    public function register(shortcut:String, callback:Void->Void):Void {
        // TODO: Реализовать через electron.globalShortcut
    }

    public function unregister(shortcut:String):Void {
        // TODO: Реализовать через electron.globalShortcut
    }
}