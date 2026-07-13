// hide/presentation/modules/ProjectModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.StubProjectFactory;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hide.presentation.ui.react.components.ProjectPanel;
class ProjectModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "project",
                label: "Project",
                description: "Дерево проекта",
                icon: "folder",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(ProjectPanel)
        };
    }
}