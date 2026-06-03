// hide/infrastructure/external/GoldenLayoutAdapter.hx

package hide.infrastructure.external;

import golden.*;
import hide.domain.services.ILayoutEngine;
import hide.domain.valueobjects.LayoutState;
import hide.domain.valueobjects.DisplayPosition;
import hide.application.dto.ViewDto;
import hide.shared.types.IEventBus; // ← ДОБАВИТЬ
import hide.shared.events.LayoutChanged; // ← ДОБАВИТЬ
//import golden.Layout;
//import golden.Config;

/**
 * Адаптер для GoldenLayout.
 * Реализует ILayoutEngine, скрывая детали JS-библиотеки.
 */
class GoldenLayoutAdapter implements ILayoutEngine {
    private var layout:Layout;
    private var container:Element;
    private var eventBus:IEventBus; // ← ДОБАВИТЬ
    private var componentRegistry:Map<String, ViewFactory>;

    // — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — —
    // 🔧 ДОБАВИТЬ:
    public function new(container:Element, eventBus:IEventBus) { // ← ДОБАВИТЬ eventBus
        this.container = container;
        this.eventBus = eventBus; // ← ДОБАВИТЬ
        this.componentRegistry = new Map();
    }
    // — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — —

    // === ILayoutEngine ===

    public function init(state:LayoutState):Void {
        // Преобразуем LayoutState → GoldenLayout Config
        var config = toGoldenConfig(state.content);
        config.settings ??= {};
        config.settings.reorderEnabled = true;
        config.settings.showPopoutIcon = false;
        config.settings.showMaximiseIcon = true;

        layout = new Layout(config, container.get(0));
        
        // Регистрация компонентов после инициализации
        for (type => factory in componentRegistry) {
            layout.registerComponent(type, function(container, state) {
                var view = factory.create(container.getElement(), state);
                return view;
            });
        }

        layout.init();
        layout.on('stateChanged', _ -> {
            // Публикация события
            eventBus.publish(new LayoutChanged({})); // ← ДОБАВИТЬ
            // Вызов callback'ов ILayoutEngine.onLayoutChanged(...)
            for (cb in onLayoutChangedCallbacks) cb();
        });
    }

    public function open(componentName:String, state:Dynamic, ?position:DisplayPosition):Void {
        if (layout == null) throw "Layout not initialized";

        var targetId = switch position {
            case Left: "left";
            case Center: "center";
            case Bottom: "bottom";
            case Right: "right";
            case MiddleColumnInternal: "middle-column";
            case null: null;
        };

        var config:Config.ItemConfig = {
            type: Component,
            componentName: componentName,
            componentState: state,
            id: targetId
        };

        var targetContainer = layout.root.getItemsById(targetId)[0] ?? layout.root;
        targetContainer.addChild(config);
    }

    public function save():LayoutState {
        var config = layout.toConfig();
        return {
            content: fromGoldenConfig(config.content),
            fullScreen: null // TODO: support fullScreen
        };
    }

    public function reopenLastClosed():Void {
        // TODO: add lastClosedTabStates management
        trace("reopenLastClosed() not implemented");
    }

    public function dispose():Void {
        if (layout != null) {
            layout.destroy();
            layout = null;
        }
        onLayoutChangedCallbacks = [];
    }

    public function onLayoutChanged(callback:Void->Void):Void {
        onLayoutChangedCallbacks.push(callback);
    }

    // === Вспомогательные методы ===

    public function registerComponent(type:String, factory:ViewFactory):Void {
        componentRegistry.set(type, factory);
        if (layout != null) {
            layout.registerComponent(type, function(container, state) {
                var view = factory.create(container.getElement(), state);
                return view;
            });
        }
    }

    private var onLayoutChangedCallbacks:Array<Void->Void> = [];

    private function onLayoutChangedCallback():Void {
        for (cb in onLayoutChangedCallbacks) cb();
    }

    // === Маппинг JSON (для GoldenLayout) ===

    private function toGoldenConfig(stateContent:Array<Dynamic>):Config {
        return {
            content: [for (item in stateContent) toGoldenItem(item)],
            settings: {
                reorderEnabled: true,
                constrainDragToHeader: true,
                showPopoutIcon: false,
                showMaximiseIcon: true
            }
        };
    }

    private function toGoldenItem(item:Dynamic):Config.ItemConfig {
        return {
            type: item.type,
            componentName: item.componentName,
            componentState: item.componentState,
            content: item.content != null ? [for (i in item.content) toGoldenItem(i)] : null,
            id: item.id,
            width: item.width,
            height: item.height
        };
    }

    private function fromGoldenConfig(items:Array<Config.ItemConfig>):Array<Dynamic> {
        return [for (item in items) fromGoldenItem(item)];
    }

    private function fromGoldenItem(item:Config.ItemConfig):Dynamic {
        return {
            type: item.type,
            componentName: item.componentName,
            componentState: item.componentState,
            content: item.content != null ? [for (i in item.content) fromGoldenItem(i)] : null,
            id: item.id,
            width: item.width,
            height: item.height
        };
    }
}

typedef ViewFactory = {
    function create(container:Element, state:Dynamic):View<Dynamic>;
}