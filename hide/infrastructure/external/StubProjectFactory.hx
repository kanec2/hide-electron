package hide.infrastructure.external;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubProjectFactory implements IViewFactory {
    public function new() {}
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#cccccc; background:#252526; height:100%; font-family: sans-serif;'>
                <h2>📁 Project Tree</h2>
                <ul>
                    <li>📂 src/</li>
                    <li>📄 Main.hx</li>
                    <li>📄 project.json</li>
                </ul>
            </div>
        ");
        return null;
    }
}