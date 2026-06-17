// hide/infrastructure/external/StubGameFactory.hx
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubGameFactory implements IViewFactory implements Service {
    public function new() {}
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#d4d4d4; background:#1a1a1a; height:100%; font-family: sans-serif; display:flex; flex-direction:column; align-items:center; justify-content:center;'>
                <div style='font-size:48px; margin-bottom:20px;'>🎮</div>
                <h2 style='margin:0; color:#fff;'>Game View</h2>
                <p style='color:#aaa; margin-top:10px;'>Press ▶ Play to run the game</p>
                <div style='margin-top:20px; padding:10px; background:#2a2a2a; border-radius:4px; font-family:monospace; font-size:12px; color:#888;'>
                    Resolution: 1920×1080 | Stats: OFF
                </div>
            </div>
        ");
        return null;
    }
}