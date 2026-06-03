package hide.infrastructure.platform.electron;

import hide.domain.services.IWindowManager;

class NwWindowManager implements IWindowManager {
    public var window:nw.Window;
    
    public function new(window:nw.Window) this.window = window;

    public function enterFullscreen() window.enterFullscreen();
    public function leaveFullscreen() window.leaveFullscreen();
    public function showDevTools() window.showDevTools();
    // и т.д.
}