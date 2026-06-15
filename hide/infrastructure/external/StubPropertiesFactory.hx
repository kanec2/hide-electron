package hide.infrastructure.external;

import hide.domain.services.IViewFactory;
import hide.domain.services.IElement;
import hx.injection.Service;

class StubPropertiesFactory implements IViewFactory implements Service {
    public function new() {}
    
    public function create(container:IElement, state:Dynamic):Dynamic {
        container.setInnerHtml("
            <div style='padding:20px; color:#cccccc; background:#252526; height:100%; font-family: sans-serif;'>
                <h2>⚙️ Properties</h2>
                <p>Object properties will appear here.</p>
            </div>
        ");
        return null;
    }
}