// hide/application/commands/ClearRecentProjectsUseCase.hx

package hide.application.commands;

import hide.application.services.MenuService;
import hide.shared.types.IEventBus;
import hide.shared.events.RecentProjectsUpdated;
import hx.injection.*;
class ClearRecentProjectsUseCase implements Service {
    private var menuService:MenuService;
    private var eventBus:IEventBus;

    public function new(menuService:MenuService, eventBus:IEventBus) {
        this.menuService = menuService;
        this.eventBus = eventBus;
    }

    public function execute():Void {
        menuService.clearRecentProjects();
        eventBus.publish(new RecentProjectsUpdated([]));
    }
}