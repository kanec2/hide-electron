// hide/presentation/modules/ConsoleModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.StubConsoleFactory;

class ConsoleModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "console",
                label: "Console",
                description: "Консоль вывода",
                icon: "terminal",
                defaultState: { logLevel: "info" }
            },
            factory: new StubConsoleFactory()
        };
    }
}