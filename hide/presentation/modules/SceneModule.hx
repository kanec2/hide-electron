// hide/presentation/modules/SceneModule.hx
package hide.presentation.modules;
import hide.application.services.IViewModule;
import hide.application.services.ViewDescriptor;
import hide.infrastructure.external.SceneViewFactory;
import hx.injection.Service;

class SceneModule implements IViewModule implements Service {
    private var sceneViewFactory:SceneViewFactory;
    
    public function new(sceneViewFactory:SceneViewFactory) {
        this.sceneViewFactory = sceneViewFactory;
    }
    
    public function getDescriptor():ViewDescriptor {
        return {
            dto: {
                name: "scene",
                label: "Scene",
                description: "3D viewport",
                icon: "film",
                defaultState: {}
            },
            factory: sceneViewFactory
        };
    }
}