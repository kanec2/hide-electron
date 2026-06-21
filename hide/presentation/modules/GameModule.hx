// hide/presentation/modules/GameModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.StubGameFactory;

class GameModule implements IViewModule {
    public function new() {}
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "game",
                label: "Game",
                description: "Game view",
                icon: "gamepad",
                defaultState: {}
            },
            factory: new StubGameFactory()
        };
    }
}