// hide/application/commands/SetFullscreenUseCase.hx

package hide.application.commands;

import hide.application.services.WindowService;
import hide.shared.types.IEventBus;
import hide.shared.events.FullscreenChanged;

class SetFullscreenUseCase {
    private var windowService:WindowService;
    private var eventBus:IEventBus;

    public function new(windowService:WindowService, eventBus:IEventBus) {
        this.windowService = windowService;
        this.eventBus = eventBus;
    }

    public function execute(enabled:Bool):Void {
        if (enabled) {
            windowService.enterFullscreen();
        } else {
            windowService.leaveFullscreen();
        }
        eventBus.publish(new FullscreenChanged(enabled));
    }
}