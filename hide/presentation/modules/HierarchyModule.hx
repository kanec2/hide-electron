// hide/presentation/modules/HierarchyModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.HierarchyPanel;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hx.injection.Service;

class HierarchyModule implements IViewModule implements Service {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "hierarchy",
                label: "Hierarchy",
                description: "Дерево объектов сцены",
                icon: "fa-sitemap",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(HierarchyPanel)
        };
    }
}