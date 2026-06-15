package hide.infrastructure.external;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubConsoleFactory implements IViewFactory  implements Service{
    public function new() {}
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#cccccc; background:#1e1e1e; height:100%; font-family: monospace;'>
                <h2>🖥️ Console</h2>
                <p>Console output will appear here.</p>
            </div>
        ");
        return null;
    }
}