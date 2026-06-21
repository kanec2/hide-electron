// hide/presentation/modules/WelcomeModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.WelcomePanel;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hx.injection.Service;

class WelcomeModule implements IViewModule implements Service {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "welcome",
                label: "Welcome",
                description: "Приветственная панель",
                icon: "fa-hand-spock",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(WelcomePanel)
        };
    }
}