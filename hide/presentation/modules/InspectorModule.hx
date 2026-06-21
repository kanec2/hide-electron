// hide/presentation/modules/InspectorModule.hx
package hide.presentation.modules;
import hide.application.services.ViewDescriptor;
import hide.application.services.IViewModule;

import hide.presentation.ui.react.components.InspectorPanel;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hx.injection.Service;

class InspectorModule implements IViewModule implements Service {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "inspector",
                label: "Inspector",
                description: "Панель свойств объекта",
                icon: "fa-info-circle",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(InspectorPanel)
        };
    }
}