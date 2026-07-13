package hide.infrastructure.external;

import hide.application.services.ViewRegistry;
import hide.infrastructure.external.golden.*;
import hide.domain.services.ILayoutEngine;
import hide.domain.services.IViewFactory;
import hide.domain.valueobjects.LayoutConfig;
import hide.domain.valueobjects.LayoutState;
import hide.domain.valueobjects.DisplayPosition;
import hide.shared.types.IEventBus;
import hide.shared.events.LayoutChanged;
import js.html.Element;
import hx.injection.Service;
import hide.infrastructure.external.golden.Config.ItemConfig;
import hide.infrastructure.external.golden.Config.ItemType;
class GoldenLayoutAdapter implements ILayoutEngine implements Service {
   private var layout:Layout;
    private var container:Dynamic; // Принимает js.html.Element или jQuery
    private var eventBus:IEventBus;
    private var viewFactories:Map<String, IViewFactory>; 
    private var onLayoutChangedCallbacks:Array<Void->Void>;
    private var viewRegistry:ViewRegistry;

    public function new(eventBus:IEventBus, viewRegistry:ViewRegistry) {
        this.eventBus = eventBus;
        this.viewRegistry = viewRegistry;
        this.viewFactories = new Map();
        this.onLayoutChangedCallbacks = [];

        viewRegistry.setFactoryRegistrationCallback(registerView);
    }

    public function setContainer(el:Dynamic):Void {
        this.container = el;
    }

    public function init(state:LayoutState):Void {
        if (container == null) {
            trace("WARNING: GoldenLayout container not set. Call setContainer() first.");
            return;
        }

        var contentData = state.content;
        if (contentData == null || contentData.length == 0) {
            var defaultState = createDefaultSkeleton();
            contentData = defaultState.content;
        }

        var goldenConfig = toGoldenConfig({ content: contentData, fullScreen: null });

        // ✅ ИСПРАВЛЕНИЕ: передаем container напрямую (или cast, если это jQuery), без .get(0)
        layout = new Layout(goldenConfig, cast container);

        for (type => factory in viewFactories) {
            registerComponentInLayout(type, factory);
        }

        layout.init();
        
        layout.on('stateChanged', onStateChanged);
    }
    private function onStateChanged ():Void {
        eventBus.publish(LayoutChanged,new LayoutChanged());
        for (cb in onLayoutChangedCallbacks) cb();
    }
    public function open(componentName:String, state:Dynamic, ?position:DisplayPosition):Void {
        if (layout == null) throw "Layout not initialized";

        var config:ItemConfig = {
            type: Component,
            componentName: componentName,
            componentState: state,
            content: [], id: null, width: null, height: null, isClosable: true, title: componentName, activeItemIndex: null
        };

        var targetContainer = getOrInitTarget(position);
        targetContainer.addChild(config);
    }
    public function updateSize(width:Int, height:Int):Void {
        if (layout != null && layout.isInitialised) {
            layout.updateSize(width, height);
        }
    }
    public function save():LayoutState {
        var config = layout.toConfig();
        return {
            // ✅ ИСПРАВЛЕНИЕ: fromGoldenConfig теперь возвращает правильный тип
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
     * Возвращает доменный тип LayoutState, а не golden.Config.
     */
    private function createDefaultSkeleton():LayoutState {
        return {
            content: [{
                type: "row",
                componentName: null,
                componentState: null,
                id: "content_root",
                width: null,
                height: null,
                content: [
                    // === ЛЕВАЯ КОЛОНКА: Hierarchy (20%) ===
                    {
                        type: "stack",
                        id: "left",
                        width: 20,
                        componentName: null,  // ← null для stack
                        componentState: null,
                        height: null,
                        content: [            // ← ДОБАВЛЯЕМ дочерний компонент!
                            {
                                type: "component",
                                componentName: "hierarchy",
                                componentState: {},
                                title: "Hierarchy",
                                id: "hierarchy-tab",
                                content: [],
                                width: null,
                                height: null
                            }
                        ],
                        title: "Hierarchy"
                    },
                    
                    // === ЦЕНТРАЛЬНАЯ КОЛОНКА (55%) ===
                    {
                        type: "column",
                        id: "middle-column",
                        width: 55,
                        componentName: null,
                        componentState: null,
                        height: null,
                        content: [
                            // Верх: Scene + Game (табы)
                            {
                                type: "stack",
                                id: "center",
                                componentName: null,
                                componentState: null,
                                width: null,
                                height: 70,
                                content: [    // ← ДОБАВЛЯЕМ Scene и Game
                                    {
                                        type: "component",
                                        componentName: "scene",
                                        componentState: {},
                                        title: "Scene",
                                        id: "scene-tab",
                                        content: [],
                                        width: null,
                                        height: null
                                    },
                                    {
                                        type: "component",
                                        componentName: "game",
                                        componentState: {},
                                        title: "Game",
                                        id: "game-tab",
                                        content: [],
                                        width: null,
                                        height: null
                                    }
                                ],
                                title: "Scene"
                            },
                            // Низ: Project + Console (табы)
                            {
                                type: "stack",
                                id: "bottom",
                                componentName: null,
                                componentState: null,
                                width: null,
                                height: 30,
                                content: [    // ← ДОБАВЛЯЕМ Project и Console
                                    {
                                        type: "component",
                                        componentName: "project",
                                        componentState: {},
                                        title: "Project",
                                        id: "project-tab",
                                        content: [],
                                        width: null,
                                        height: null
                                    },
                                    {
                                        type: "component",
                                        componentName: "console",
                                        componentState: { logLevel: "info" },
                                        title: "Console",
                                        id: "console-tab",
                                        content: [],
                                        width: null,
                                        height: null
                                    }
                                ],
                                title: "Project"
                            }
                        ]
                    },
                    
                    // === ПРАВАЯ КОЛОНКА: Inspector (25%) ===
                    {
                        type: "stack",
                        id: "right",
                        width: 25,
                        componentName: null,
                        componentState: null,
                        height: null,
                        content: [            // ← ДОБАВЛЯЕМ дочерний компонент!
                            {
                                type: "component",
                                componentName: "inspector",
                                componentState: {},
                                title: "Inspector",
                                id: "inspector-tab",
                                content: [],
                                width: null,
                                height: null
                            }
                        ],
                        title: "Inspector"
                    }
                ]
            }],
            fullScreen: null
        };
    }

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

        var items = layout.root.getItemsById(targetId);
        if (items.length > 0) {
            var target = items[0];
            // ✅ ЗАЩИТА: если у существующего контейнера content == null, инициализируем
            if (target.config.content == null) {
                target.config.content = [];
            }
            return target;
        }

        var rootRow = layout.root.contentItems[0];
        if (rootRow == null || rootRow.type != Row) {
            layout.root.addChild({ type: Stack, id: targetId, componentName: null, componentState: null, content: [], width: null, height: null, isClosable: true, title: null, activeItemIndex: null });
            return layout.root.getItemsById(targetId)[0];
        }

        switch position {
            case Left: rootRow.addChild({ type: Stack, id: "left", width: 20, componentName: null, componentState: null, content: [], height: null, isClosable: true, title: null, activeItemIndex: null }, 0);
            case Right: rootRow.addChild({ type: Stack, id: "right", width: 20, componentName: null, componentState: null, content: [], height: null, isClosable: true, title: null, activeItemIndex: null });
            case Center | Bottom | MiddleColumnInternal:
                var middleItems = layout.root.getItemsById("middle-column");
                var middleCol:ContentItem = middleItems.length > 0 ? middleItems[0] : null;

                if (middleCol == null) {
                    rootRow.addChild({ type: Column, id: "middle-column", isClosable: false, componentName: null, componentState: null, content: [], width: null, height: null, title: null, activeItemIndex: null }, 1);
                    middleCol = layout.root.getItemsById("middle-column")[0];
                }

                if (position == Center) {
                    middleCol.addChild({ type: Stack, id: "center", componentName: null, componentState: null, content: [], width: null, height: null, isClosable: true, title: null, activeItemIndex: null }, 0);
                } else if (position == Bottom) {
                    middleCol.addChild({ type: Stack, id: "bottom", componentName: null, componentState: null, content: [], width: null, height: null, isClosable: true, title: null, activeItemIndex: null });
                }
            default:
        }
        return layout.root.getItemsById(targetId)[0];
    }

    // === Строгий Маппинг JSON ===
    
    private function toGoldenConfig(state:LayoutState):Config {
        return {
            content: [for (item in state.content) toGoldenItem(item)],
            settings: { 
                reorderEnabled: true,       // ✅ РАЗРЕШАЕМ ПЕРЕТАСКИВАНИЕ
                constrainDragToContainer: true,
                constrainDragToHeader: false, // ✅ Позволяем тащить за любую часть вкладки, а не только за заголовок
                showPopoutIcon: false,
                showMaximiseIcon: true 
            }
        };
    }

    // ✅ ИСПРАВЛЕНИЕ: Явная типизация аргумента
    // hide/infrastructure/external/GoldenLayoutAdapter.hx
    private function toGoldenItem(item:LayoutConfig):hide.infrastructure.external.golden.Config.ItemConfig {
        var glType = switch item.type {
            case "row": ItemType.Row;
            case "column": ItemType.Column;
            case "stack": ItemType.Stack;
            default: ItemType.Component;
        };
        return {
            type: glType,
            componentName: item.componentName,
            componentState: item.componentState,
            content: item.content != null ? [for (i in item.content) toGoldenItem(i)] : null,
            id: item.id,
            width: item.width,
            height: item.height,
            isClosable: true,
            title: item.title,          // ← ИЗМЕНЕНО: было null
            activeItemIndex: null
        };
    }

    // ✅ ИСПРАВЛЕНИЕ: Возвращаем правильный доменный тип
    private function fromGoldenConfig(items:Array<ItemConfig>):Array<LayoutConfig> {
        return [for (item in items) fromGoldenItem(item)];
    }

    // hide/infrastructure/external/GoldenLayoutAdapter.hx
    private function fromGoldenItem(item:ItemConfig):LayoutConfig {
        var typeStr = switch item.type {
            case Row: "row";
            case Column: "column";
            case Stack: "stack";
            case Component: "component";
        };
        return {
            type: typeStr,
            componentName: item.componentName,
            componentState: item.componentState,
            content: item.content != null ? [for (i in item.content) fromGoldenItem(i)] : null,
            id: item.id,
            width: item.width,
            height: item.height,
            title: item.title           // ← ДОБАВИТЬ
        };
    }
}