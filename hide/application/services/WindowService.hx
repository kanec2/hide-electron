package hide.application.services;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;

/**
 * Сервис управления окном для уровня приложения.
 * Кеширует состояние, транслирует события, скрывает детали платформы.
 */
class WindowService {
    private var manager:IWindowManager;
    
    // Состояние (автоматически обновляется через события)
    public var isFullscreen(default, null):Bool = false;
    public var isMaximized(default, null):Bool = false;
    public var bounds(get, never):WindowBounds;
    
    public function new(manager:IWindowManager) {
        this.manager = manager;
        setupStateSync();
    }
    
    // === Публичное API ===
    public function resizeBy(dw:Int, dh:Int):Void { manager.resizeBy(dw, dh); }
    public function moveTo(x:Int, y:Int):Void { manager.moveTo(x, y); }
    public function setFullscreen(value:Bool):Void {
        manager.setFullscreen(value);
        isFullscreen = value;
        if (value) isMaximized = false; // Fullscreen сбрасывает maximize
    }
    public function maximize():Void { manager.maximize(); isMaximized = true; }
    public function unmaximize():Void { manager.unmaximize(); isMaximized = false; }
    public function focus():Void { manager.focus(); }
    public function blur():Void { manager.blur(); }
    public function setTitle(title:String):Void { manager.setTitle(title); }
    
    private function get_bounds():WindowBounds {
        return manager.getBounds();
    }
    
    // === Синхронизация состояния через события ===
    private function setupStateSync():Void {
        manager.on(Maximize, _ -> { isMaximized = true; isFullscreen = false; });
        manager.on(Unmaximize, _ -> { isMaximized = false; });
        manager.on(Restore, _ -> { isMaximized = false; isFullscreen = false; });
        manager.on(Minimize, _ -> { /* можно добавить флаг isMinimized при необходимости */ });
    }
    
    // Проброс подписок для Presentation layer
    public function on(event:WindowEvent, cb:Dynamic->Void):Void { manager.on(event, cb); }
    public function off(event:WindowEvent, cb:Dynamic->Void):Void { manager.off(event, cb); }
}