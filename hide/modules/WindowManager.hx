package hide.modules;

import hide.core.Ide;

class WindowManager {
    var ide:Ide;
    
    // Ссылка на экземпляр GoldenLayout (устанавливается из Ide/UI)
    public var goldenLayout:Dynamic = null;
    
    // Зарегистрированные компоненты
    var registeredComponents:Map<String, Class<Dynamic>> = new Map();

    public function new(ide:Ide) { 
        this.ide = ide; 
    }
    
    /**
     * Регистрация Haxe-класса как компонента GoldenLayout
     * Вызывать при инициализации приложения
     */
    public function registerComponent(name:String, clazz:Class<Dynamic>):Void {
        registeredComponents.set(name, clazz);
        trace("[WindowManager] ✅ Registered component: " + name);
    }
    
    /**
     * Открытие суб-вью как панели в GoldenLayout
     */
    public function openSubView(componentName:String, ?state:Dynamic, ?position:String):Void {
        trace("[WindowManager] 🪟 Opening dockable view: " + componentName);
        
        if (goldenLayout == null) {
            trace("[WindowManager] ⚠️ GoldenLayout not initialized yet");
            return;
        }
        
        // Подготовка состояния компонента
        var componentState = {
            componentName: componentName,
            ide: ide,
            config: state != null ? state : {}
        };
        
        // Добавление панели в layout
        // position: "content_left", "content_right", или null (центр)
        try {
            if (position != null && position != "") {
                // Добавление в конкретную сторону
                var side = switch position {
                    case "content_left": "left";
                    case "content_right": "right"; 
                    case "content_bottom": "bottom";
                    case _: "center";
                };
                goldenLayout.root.contentItems[0].addChild({
                    type: "component",
                    componentName: componentName,
                    componentState: componentState
                }, side == "left" ? 0 : -1);
            } else {
                // Добавление в активную панель
                goldenLayout.root.contentItems[0].addChild({
                    type: "component", 
                    componentName: componentName,
                    componentState: componentState
                });
            }
            trace("[WindowManager] ✅ Panel added: " + componentName);
        } catch (e:Dynamic) {
            trace("[WindowManager] ❌ Failed to add panel: " + e);
        }
    }
    
    public function closeAll():Void {
        trace("[WindowManager] Closing all panels");
        // GoldenLayout сам управляет закрытием, можно добавить логику сохранения
    }
    
    /**
     * Вызывается из Ide/UI после инициализации GoldenLayout
     */
    public function setGoldenLayout(gl:Dynamic):Void {
        goldenLayout = gl;
        trace("[WindowManager] 🔗 GoldenLayout connected");
        
        // Авто-регистрация известных компонентов
        registerComponent("hide.view.FileBrowser", null); // Заглушка, реальная регистрация ниже
        registerComponent("hide.view.CdbTable", null);
        // ... добавить остальные
    }
}