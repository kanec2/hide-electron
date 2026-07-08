package hide.infrastructure.platform.electron.nwjs;


import hide.domain.valueobjects.ScreenBounds;
import hx.injection.Service;
class NwScreenAdapte implements Service {
    public function new() {}
    public function getPrimaryDisplay():ScreenBounds {
        // TODO: Реализовать через nw.Screen
        return { x: 0, y: 0, width: 1920, height: 1080 };
    }

    public function getAllDisplays():Array<ScreenBounds> {
        // TODO: Реализовать через nw.Screen
        return [];
    }
}