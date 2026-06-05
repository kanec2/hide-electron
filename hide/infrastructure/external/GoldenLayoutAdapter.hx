package hide.infrastructure.external;

import hide.application.services.ViewRegistry;
import golden.*;
import hide.domain.services.ILayoutEngine;
import hide.domain.services.IViewFactory;
import hide.domain.valueobjects.LayoutState;
import hide.domain.valueobjects.DisplayPosition;
import hide.shared.types.IEventBus;
import hide.shared.events.LayoutChanged;
import js.html.Element;

class GoldenLayoutAdapter implements ILayoutEngine {
    private var layout:Layout;
    private var container:Element;
    private var eventBus:IEventBus;
    
    // ✅ 1. Инициализация Map
    private var viewFactories:Map<String, IViewFactory>; 
    private var onLayoutChangedCallbacks:Array<Void->Void>;
    private var viewRegistry:ViewRegistry;

    public function new(container:Element, eventBus:IEventBus, viewRegistry:ViewRegistry) {
        this.container = container;
        this.eventBus = eventBus;
        this.viewRegistry = viewRegistry;
        this.viewFactories = new Map(); // ✅ ИСПРАВЛЕНО: Создаем Map
        this.onLayoutChangedCallbacks = [];

        // ✅ 3. Подписываемся на новые регистрации в ViewRegistry
        // Когда плагин вызовет viewRegistry.registerViewFactory, сработает этот коллбэк
        viewRegistry.setFactoryRegistrationCallback(registerView);
    }

    public function init(state:LayoutState):Void {
        // ✅ 2. Обработка "Пустого старта"
        var contentData = state.content;
        if (contentData == null || contentData.length == 0) {
            contentData = createDefaultSkeleton().content;
        }

        var config = toGoldenConfig(contentData);
        config.settings ??= {};
        config.settings.reorderEnabled = true;
        config.settings.showPopoutIcon = false;
        config.settings.showMaximiseIcon = true;

        layout = new Layout(config, container.get(0));

        // Регистрация ВСЕХ существующих фабрик из ViewRegistry ПЕРЕД init()
        for (type => factory in viewFactories) {
            registerComponentInLayout(type, factory);
        }

        layout.init();
        
        layout.on('stateChanged', _ -> {
            eventBus.publish(new LayoutChanged({}));
            for (cb in onLayoutChangedCallbacks) cb();
        });
    }

    public function open(componentName:String, state:Dynamic, ?position:DisplayPosition):Void {
        if (layout == null) throw "Layout not initialized";

        var config:Config.ItemConfig = {
            type: Component,
            componentName: componentName,
            componentState: state
        };

        // ✅ 2. Безопасное получение или создание контейнера
        var targetContainer = getOrInitTarget(position);
        targetContainer.addChild(config);
    }

    public function save():LayoutState {
        var config = layout.toConfig();
        return {
            content: fromGoldenConfig(config.content),
            fullScreen: null
        };
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

    public function registerView(type:String, factory:IViewFactory):Void {
        viewFactories.set(type, factory);
        
        // Если Layout уже инициализирован (плагин загрузился на лету), регистрируем сразу
        if (layout != null && layout.isInitialised) {
            registerComponentInLayout(type, factory);
        }
    }

    // === Вспомогательные методы ===

    private function registerComponentInLayout(type:String, factory:IViewFactory):Void {
        layout.registerComponent(type, function(glContainer, state) {
            var element = new HtmlElement(glContainer.getElement());
            factory.create(element, state);
        });
    }

    /**
     * Создает дефолтную структуру окон, если её нет.
     */
    private function createDefaultSkeleton():Config {
        return {
            content: [{
                type: Row,
                content: [
                    { type: Stack, id: "left", width: 20 },      
                    { type: Column, id: "middle-column", width: 60, content: [
                        { type: Stack, id: "center" },            
                        { type: Stack, id: "bottom", height: 30 } 
                    ]},
                    { type: Stack, id: "right", width: 20 }      
                ]
            }],
            settings: {}
        };
    }

    /**
     * Находит контейнер по позиции или создает его, если он был удален пользователем.
     * Это критически важно для IDE!
     */
    private function getOrInitTarget(position:DisplayPosition):ContentItem {
        if (layout.root == null) return layout.root;

        var targetId = switch position {
            case Left: "left";
            case Center: "center";
            case Bottom: "bottom";
            case Right: "right";
            case MiddleColumnInternal: "middle-column";
            case null: null;
        };

        if (targetId == null) return layout.root;

        // 1. Пытаемся найти существующий
        var items = layout.root.getItemsById(targetId);
        if (items.length > 0) return items[0];

        // 2. Создаем недостающий (упрощенная логика для основных зон)
        var rootRow = layout.root.contentItems[0];
        if (rootRow == null || rootRow.type != Row) {
            // Если корень не Row, добавляем в корень
            var newStack:Config.ItemConfig = { type: Stack, id: targetId };
            layout.root.addChild(newStack);
            return layout.root.getItemsById(targetId)[0];
        }

        switch position {
            case Left:
                // Вставляем в начало корневого Row
                rootRow.addChild({ type: Stack, id: "left", width: 20 }, 0);
            
            case Right:
                // Вставляем в конец корневого Row
                rootRow.addChild({ type: Stack, id: "right", width: 20 });

            case Center | Bottom | MiddleColumnInternal:
                // Ищем или создаем "middle-column"
                var middleItems = layout.root.getItemsById("middle-column");
                var middleCol:ContentItem = middleItems.length > 0 ? middleItems[0] : null;

                if (middleCol == null) {
                    // Создаем Column посередине (индекс 1, между left и right)
                    rootRow.addChild({ type: Column, id: "middle-column", isClosable: false }, 1);
                    middleCol = layout.root.getItemsById("middle-column")[0];
                }

                if (position == Center) {
                    middleCol.addChild({ type: Stack, id: "center" }, 0);
                } else if (position == Bottom) {
                    middleCol.addChild({ type: Stack, id: "bottom" });
                }
            
            default:
                return layout.root;
        }

        // Возвращаем свеже созданный
        return layout.root.getItemsById(targetId)[0];
    }

    // === Маппинг JSON (без изменений) ===
    private function toGoldenConfig(stateContent:Array<Dynamic>):Config {
        return {
            content: [for (item in stateContent) toGoldenItem(item)],
            settings: { reorderEnabled: true, constrainDragToHeader: true, showPopoutIcon: false, showMaximiseIcon: true }
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