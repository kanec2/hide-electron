// hide/infrastructure/external/StubInspectorFactory.hx
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubInspectorFactory implements IViewFactory implements Service {
    public function new() {}
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:10px; color:#d4d4d4; background:#383838; height:100%; font-family: sans-serif; font-size:13px; overflow-y:auto;'>
                <div style='padding:8px; background:#2a2a2a; border-radius:3px; margin-bottom:8px;'>
                    <div style='display:flex; align-items:center; gap:8px;'>
                        <input type='checkbox' checked/>
                        <b style='color:#fff;'>🎭 Player</b>
                        <span style='margin-left:auto; color:#888; font-size:11px;'>Tag: Player</span>
                    </div>
                </div>
                
                <div style='background:#2a2a2a; border-radius:3px; margin-bottom:6px;'>
                    <div style='padding:6px 8px; background:#3a3a3a; font-weight:bold; border-bottom:1px solid #222;'>
                        🔽 Transform
                    </div>
                    <div style='padding:8px;'>
                        <div style='display:flex; gap:4px; margin-bottom:4px;'>
                            <span style='width:60px; color:#aaa;'>Position</span>
                            <input value='0' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='1.5' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='0' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                        <div style='display:flex; gap:4px; margin-bottom:4px;'>
                            <span style='width:60px; color:#aaa;'>Rotation</span>
                            <input value='0' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='0' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='0' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                        <div style='display:flex; gap:4px;'>
                            <span style='width:60px; color:#aaa;'>Scale</span>
                            <input value='1' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='1' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                            <input value='1' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                    </div>
                </div>
                
                <div style='background:#2a2a2a; border-radius:3px; margin-bottom:6px;'>
                    <div style='padding:6px 8px; background:#3a3a3a; font-weight:bold; border-bottom:1px solid #222;'>
                        🔽 Mesh Renderer
                    </div>
                    <div style='padding:8px;'>
                        <div style='display:flex; gap:4px; margin-bottom:4px;'>
                            <span style='width:60px; color:#aaa;'>Mesh</span>
                            <input value='Player.mesh' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                        <div style='display:flex; gap:4px;'>
                            <span style='width:60px; color:#aaa;'>Material</span>
                            <input value='Default-Diffuse' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                    </div>
                </div>
                
                <div style='background:#2a2a2a; border-radius:3px;'>
                    <div style='padding:6px 8px; background:#3a3a3a; font-weight:bold; border-bottom:1px solid #222;'>
                        🔽 Rigidbody
                    </div>
                    <div style='padding:8px;'>
                        <div style='display:flex; gap:4px; margin-bottom:4px;'>
                            <span style='width:60px; color:#aaa;'>Mass</span>
                            <input value='1' style='flex:1; background:#1a1a1a; border:1px solid #555; color:#fff; padding:2px 4px; border-radius:2px;'/>
                        </div>
                        <div style='display:flex; gap:4px;'>
                            <span style='width:60px; color:#aaa;'>Gravity</span>
                            <input type='checkbox' checked/>
                        </div>
                    </div>
                </div>
                
                <div style='margin-top:10px; text-align:center;'>
                    <button style='background:#4a4a4a; color:#fff; border:1px solid #555; padding:4px 12px; border-radius:3px; cursor:pointer;'>Add Component</button>
                </div>
            </div>
        ");
        return null;
    }
}