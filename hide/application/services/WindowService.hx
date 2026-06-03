package hide.application.services;

import hide.domain.services.IWindowManager;
import hide.domain.enums.WindowEvent;
import hide.domain.valueobjects.WindowBounds;

/**
 * Сервис управления окном для уровня приложения.
 * Кеширует состояние, транслирует события, скрывает детали платформы.
 * Поддерживает: showDevTools, fullscreen, close handlers, move/resize, focus, title.
 */
class WindowService {
    private var manager:IWindowManager;
    
    // === Состояние ===
    public var isFullscreen(default, null):Bool = false;
    public var isMaximized(default, null):Bool = false;
    public var isFocused(default, null):Bool = false;
    public var bounds(get, never):WindowBounds;
    
    // === Конструктор ===
    public function new(manager:IWindowManager) {
        this.manager = manager;
        setupStateSync();
    }

    // === Публичное API ===
    public function resizeBy(dw:Int, dh:Int):Void { manager.resizeBy(dw, dh); }
    public function moveTo(x:Int, y:Int):Void { manager.moveTo(x, y); }
    public function maximize():Void { manager.maximize(); isMaximized = true; }
    public function unmaximize():Void { manager.unmaximize(); isMaximized = false; }
    public function focus():Void { manager.focus(); isFocused = true; }
    public function blur():Void { manager.blur(); isFocused = false; }
    public function setTitle(title:String):Void { manager.setTitle(title); }
    public function getTitle():String return manager.getTitle();

    // --- Фуллскрин (NW.js-совместимый) ---
    public function enterFullscreen():Void {
        manager.enterFullscreen();
        isFullscreen = true;
        isMaximized = false; // NW.js сбрасывает maximize при fullscreen
    }
    public function leaveFullscreen():Void {
        manager.leaveFullscreen();
        isFullscreen = false;
    }

    // --- Другие методы ---
    public function showDevTools():Void { manager.showDevTools(); }

    // --- Обработка событий ===
    public function onClose(callback:Void->Void):Void { manager.on(WindowEvent.Close, _ -> callback()); }
    public function onMove(callback:Void->Void):Void { manager.on(WindowEvent.Move, _ -> haxe.Timer.delay(callback, 100)); }
    public function onResize(callback:Void->Void):Void { manager.on(WindowEvent.Resize, _ -> haxe.Timer.delay(callback, 100)); }
    public function onBlur(callback:Void->Void):Void { manager.on(WindowEvent.Blur, _ -> { isFocused = false; callback(); }); }
    public function onFocus(callback:Void->Void):Void { manager.on(WindowEvent.Focus, _ -> { isFocused = true; callback(); }); }

    // --- Проброс событий через `on(event, cb)` (для старой сигнатуры) ---
    public function on(event:WindowEvent, cb:Dynamic->Void):Void { manager.on(event, cb); }
    public function off(event:WindowEvent, cb:Dynamic->Void):Void { manager.off(event, cb); }

    // === Геттеры ===
    private function get_bounds():WindowBounds {
        var raw = manager.getBounds();
        // Уточнение: if (isMaximized) возвращаем bounds.maximized, иначе .normal
        return raw;
    }

    // === Синхронизация состояния через события ===
    private function setupStateSync():Void {
        manager.on(WindowEvent.Maximize, _ -> {
            isMaximized = true;
            isFullscreen = false;
        });

        manager.on(WindowEvent.Restore, _ -> {
            isMaximized = false;
            isFullscreen = false;
        });

        manager.on(WindowEvent.FullscreenEnter, _ -> {
            isFullscreen = true;
            isMaximized = false; // NW.js сбрасывает maximize при fullscreen
        });

        manager.on(WindowEvent.FullscreenLeave, _ -> {
            isFullscreen = false;
        });

        manager.on(WindowEvent.Move, _ -> { /* можно добавить isMoved, если нужно */ });
        manager.on(WindowEvent.Resize, _ -> { /* можно добавить isResized */ });
    }

    // === Ресурсоосвобождение ===
    public function dispose():Void {
        manager.dispose(); // очистить подписки, если поддерживается
    }
}