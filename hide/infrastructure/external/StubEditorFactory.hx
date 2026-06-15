package hide.infrastructure.external;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubEditorFactory implements IViewFactory implements Service {
    public function new() {}
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#d4d4d4; background:#1e1e1e; height:100%; font-family: monospace;'>
                <h2>📝 Stub Editor</h2>
                <p>Здесь будет <b>Monaco Editor</b>.</p>
                <p>Состояние: " + haxe.Json.stringify(state) + "</p>
            </div>
        ");
        return null;
    }
}