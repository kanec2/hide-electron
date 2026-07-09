// hide/presentation/modules/EditorModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.EditorView;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hx.injection.Service;
/**
Модуль редактора кода на базе Monaco Editor.
*/
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
            factory: new ReactViewFactory().withComponent(EditorView)
        };
    }
}