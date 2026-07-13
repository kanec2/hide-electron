package hide.presentation.modules;

import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.presentation.ui.react.components.AssetBrowserPanel;
import hide.presentation.ui.react.factories.ReactViewFactory;

class AssetBrowserModule implements IViewModule {
    public function new() {}

    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "asset-browser",
                label: "Asset Browser",
                description: "Управление ресурсами проекта",
                icon: "fa-image",
                defaultState: {}
            },
            factory: new ReactViewFactory().withComponent(AssetBrowserPanel)
        };
    }
}