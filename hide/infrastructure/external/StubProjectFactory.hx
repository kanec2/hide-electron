// hide/infrastructure/external/StubProjectFactory.hx (улучшаем существующий)
package hide.infrastructure.external;
import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubProjectFactory implements IViewFactory implements Service {
    public function new() {}
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:10px; color:#d4d4d4; background:#383838; height:100%; font-family: sans-serif; font-size:13px;'>
                <div style='padding:4px 8px; background:#2a2a2a; border-radius:3px; margin-bottom:8px;'>
                    🔍 <input type='text' placeholder='Search Assets...' style='background:transparent; border:none; color:#fff; outline:none; width:80%;'/>
                </div>
                <div style='display:flex; height:calc(100% - 40px); gap:8px;'>
                    <div style='flex:1; background:#2a2a2a; border-radius:3px; padding:8px; overflow-y:auto;'>
                        <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                            ▼ 📁 Assets
                        </div>
                        <div style='padding-left:16px;'>
                            <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                                ▼ 📁 Materials
                            </div>
                            <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                                ▼ 📁 Prefabs
                            </div>
                            <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                                ▼ 📁 Scenes
                            </div>
                            <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                                ▼ 📁 Scripts
                            </div>
                            <div style='padding-left:16px;'>
                                <div style='padding:3px 6px; cursor:pointer; border-radius:3px; color:#7ec6ff;'>📄 PlayerController.cs</div>
                                <div style='padding:3px 6px; cursor:pointer; border-radius:3px; color:#7ec6ff;'>📄 GameManager.cs</div>
                            </div>
                            <div style='padding:3px 6px; cursor:pointer; border-radius:3px;' onmouseover='this.style.background=\"#444\"' onmouseout='this.style.background=\"transparent\"'>
                                📁 Textures
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        ");
        return null;
    }
}