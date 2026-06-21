// hide/presentation/modules/ShaderEditorModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.ShaderEditorPanel;
import hide.presentation.ui.react.factories.ReactViewFactory;

class ShaderEditorModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "shadereditor",
                label: "Shader Editor",
                description: "Редактор шейдеров",
                icon: "paint-brush",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(ShaderEditorPanel)
        };
    }
}