package hide.infrastructure.external;

import hide.domain.services.ILayoutEngine;
import hide.domain.entities.LayoutConfig;
import hide.application.dto.PanelDto;

/**
 * Адаптер для GoldenLayout.
 * Реализует ILayoutEngine, скрывая детали JS-библиотеки.
 */
class GoldenLayoutAdapter implements ILayoutEngine {
    private var layout:Dynamic; // golden.Layout
    private var container:Element;
    private var componentRegistry:Map<String, PanelFactory>;
    
    public function new(container:Element) {
        this.container = container;
        this.componentRegistry = new Map();
    }
    
    public function registerComponent(type:String, factory:PanelFactory):Void {
        componentRegistry.set(type, factory);
        
        // Регистрация в GoldenLayout (JS interop)
        if (layout != null) {
            layout.registerComponent(type, function(container, state) {
                var panel = factory.create(container.getElement(), state);
                panel.render();
                return panel;
            });
        }
    }
    
    public function openPanel(type:String, state:Dynamic, ?position:PanelPosition):Void {
        // Логика добавления панели в нужное место
        // ...
    }
    
    public function saveState():LayoutConfig {
        return LayoutConfig.fromJson(layout.toConfig());
    }
    
    public function restoreState(config:LayoutConfig):Void {
        layout = new golden.Layout(config.toJson(), container.get(0));
        
        // Перерегистрируем компоненты после создания лейаута
        for (type => factory in componentRegistry) {
            layout.registerComponent(type, function(container, state) {
                var panel = factory.create(container.getElement(), state);
                panel.render();
                return panel;
            });
        }
        
        layout.init();
    }
}

typedef PanelFactory = {
    function create(container:Element, state:Dynamic):View<Dynamic>;
}