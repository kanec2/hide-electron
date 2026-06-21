// hide/presentation/modules/PropertiesModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.StubPropertiesFactory;

class PropertiesModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "properties",
                label: "Properties",
                description: "Свойства объекта",
                icon: "cog",
                defaultState: {}
            },
            factory: new StubPropertiesFactory()
        };
    }
}