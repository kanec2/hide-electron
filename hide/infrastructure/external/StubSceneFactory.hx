// hide/infrastructure/external/StubSceneFactory.hx
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubSceneFactory implements IViewFactory implements Service {
    public function new() {}
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#d4d4d4; background:#383838; height:100%; font-family: sans-serif; display:flex; flex-direction:column; align-items:center; justify-content:center;'>
                <div style='font-size:48px; margin-bottom:20px;'>🎬</div>
                <h2 style='margin:0; color:#fff;'>Scene View</h2>
                <p style='color:#aaa; margin-top:10px;'>3D viewport will appear here</p>
                <div style='margin-top:20px; padding:10px; background:#2a2a2a; border-radius:4px; font-family:monospace; font-size:12px;'>
                    <div>📷 Camera: Main Camera</div>
                    <div>🎯 Gizmos: ON</div>
                    <div>💡 Lighting: Baked</div>
                </div>
            </div>
        ");
        return null;
    }
}