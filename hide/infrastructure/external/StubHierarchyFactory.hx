// hide/infrastructure/external/StubHierarchyFactory.hx
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubHierarchyFactory implements IViewFactory implements Service {
    public function new() {}
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:10px; color:#d4d4d4; background:#383838; height:100%; font-family: sans-serif; font-size:13px;'>
                <div style='padding:4px 8px; background:#2a2a2a; border-radius:3px; margin-bottom:8px;'>
                    🔍 <input type='text' placeholder='Search...' style='background:transparent; border:none; color:#fff; outline:none; width:80%;'/>
                </div>
                <div style='padding:4px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                    ▼ 🎬 <b>SampleScene</b>
                </div>
                <div style='padding-left:20px;'>
                    <div style='padding:3px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                        ▼ 📷 Main Camera
                    </div>
                    <div style='padding:3px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                        💡 Directional Light
                    </div>
                    <div style='padding:3px 8px; cursor:pointer; border-radius:3px; background:#2d5c8a;' >
                        🎭 Player
                    </div>
                    <div style='padding-left:20px;'>
                        <div style='padding:3px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                            🎨 MeshRenderer
                        </div>
                        <div style='padding:3px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                            🎮 Rigidbody
                        </div>
                    </div>
                    <div style='padding:3px 8px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                        🧱 Ground
                    </div>
                </div>
            </div>
        ");
        return null;
    }
}