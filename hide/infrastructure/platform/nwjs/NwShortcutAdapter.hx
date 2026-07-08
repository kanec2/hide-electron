package hide.infrastructure.platform.electron.nwjs;


import hx.injection.Service;
class NwShortcutAdapter implements Service {
    public function new() {}
    public function register(shortcut:String, callback:Void->Void):Void {
        // TODO: Реализовать через nw.Shortcut
    }

    public function unregister(shortcut:String):Void {
        // TODO: Реализовать через nw.Shortcut
    }
}