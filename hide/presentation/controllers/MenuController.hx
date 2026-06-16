package hide.presentation.controllers;

import hide.application.services.MenuService;
import hide.presentation.ui.MenuBuilder;
import hide.shared.types.IEventBus;
import hide.shared.events.RecentProjectsUpdated;
import js.html.Element;
import tink.core.*;
import hx.injection.Service; // <-- Добавляем маркер DI

using tink.CoreApi;
using StringTools;
class MenuController implements Service {
    private var menuService:MenuService;
    private var eventBus:IEventBus;
    private var container:Null<Element>;
    private var recentProjectsUnsub:CallbackLink;

    // ✅ DI-контейнер автоматически разрешит эти зависимости
    public function new(menuService:MenuService, eventBus:IEventBus) {
        this.menuService = menuService;
        this.eventBus = eventBus;
    }

    /**
     * ✅ DOM-элемент передается отдельно, так как это инфраструктурная деталь, 
     * а не бизнес-сервис. Это тот же паттерн, что и в GoldenLayoutAdapter.setContainer()
     */
    public function setContainer(el:Element):Void {
        this.container = el;
        render();
        attachEvents();
        
        // Подписываемся на обновления после привязки к DOM
        recentProjectsUnsub = eventBus.subscribe(RecentProjectsUpdated, function(e:RecentProjectsUpdated) {
            render();
        });
    }

    private function render():Void {
        if (container == null) return;
        container.innerHTML = "";
        var menuEl = MenuBuilder.build(menuService.getMenuStructure());
        container.appendChild(menuEl);
        container.style.display = "block"; // Убеждаемся, что оно видимо
    }

    private function attachEvents():Void {
        if (container == null) return;
        
        container.addEventListener("click", function(e:js.html.MouseEvent) {
            var target = cast(e.target, js.html.Element);
            var btn = target.closest("button[data-menu-id]");
            
            if (btn != null) {
                var id = btn.getAttribute("data-menu-id");
                var parentLi = cast(btn.parentNode, js.html.Element);
                
                if (id != null && id != "" && !parentLi.className.contains("disabled")) {
                    menuService.trigger(id);
                }
            }
        });
    }

    public function dispose():Void {
        if (recentProjectsUnsub != null) {
            recentProjectsUnsub.cancel();
        }
    }
}