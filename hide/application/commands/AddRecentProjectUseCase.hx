// hide/application/commands/AddRecentProjectUseCase.hx

package hide.application.commands;

import hide.application.services.MenuService;
import hide.shared.types.IEventBus;
import hide.shared.events.RecentProjectsUpdated;
import hx.injection.*;
class AddRecentProjectUseCase implements Service {
    private var menuService:MenuService;
    private var eventBus:IEventBus;

    public function new(menuService:MenuService, eventBus:IEventBus) {
        this.menuService = menuService;
        this.eventBus = eventBus;
    }

    public function execute(path:String):Void {
        menuService.addRecentProject(path);
        eventBus.publish(new RecentProjectsUpdated(menuService.getRecentProjects()));
    }
}