// hide/presentation/modules/EditorModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.StubEditorFactory;

class EditorModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "editor",
                label: "Editor",
                description: "Редактор кода",
                icon: "code",
                defaultState: {}
            },
            factory: new StubEditorFactory()
        };
    }
}