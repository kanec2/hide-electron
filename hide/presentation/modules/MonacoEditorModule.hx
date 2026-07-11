package hide.presentation.modules;

import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.MonacoEditorView;
import hide.presentation.ui.react.factories.ReactViewFactory;
import hx.injection.Service;

/**
Модуль редактора кода на базе Monaco Editor с @monaco-editor/react.
*/
class MonacoEditorModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "monaco-editor",
                label: "Monaco Editor",
                description: "Редактор кода на базе Monaco Editor",
                icon: "code",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(MonacoEditorView)
        };
    }
}