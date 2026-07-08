package hide.infrastructure.platform.electron;

import hide.domain.services.IScreenService;
import hide.domain.valueobjects.ScreenBounds;
import hx.injection.Service;
class ElectronScreenAdapter implements IScreenService implements Service {
    public function new() {}
    public function getPrimaryDisplay():ScreenBounds {
        // TODO: Реализовать через electron.screen
        return { x: 0, y: 0, width: 1920, height: 1080 };
    }

    public function getAllDisplays():Array<ScreenBounds> {
        // TODO: Реализовать через electron.screen
        return [];
    }
}