package hide.presentation.controllers;

import hide.application.services.WindowService;
import hide.shared.types.IEventBus;
import hide.shared.events.FullscreenChanged;
import js.html.Element;
import tink.core.*;
import hx.injection.Service;

using tink.CoreApi;

class WindowController implements Service {
    private var windowService:WindowService;
    private var eventBus:IEventBus;
    
    private var btnMinimize:Null<Element>;
    private var btnMaximize:Null<Element>;
    private var btnClose:Null<Element>;
    
    private var fullscreenUnsub:CallbackLink;
    
    public function new(windowService:WindowService, eventBus:IEventBus) {
        this.windowService = windowService;
        this.eventBus = eventBus;
    }
    
    public function init():Void {
        btnMinimize = js.Browser.document.getElementById("btn-minimize");
        btnMaximize = js.Browser.document.getElementById("btn-maximize");
        btnClose = js.Browser.document.getElementById("btn-close");
        
        attachEvents();
        subscribeToEvents();
        updateMaximizeIcon();
    }
    
    private function attachEvents():Void {
        if (btnMinimize != null) {
            btnMinimize.addEventListener("click", function(_) {
                windowService.minimize();
            });
        }
        
        if (btnMaximize != null) {
            btnMaximize.addEventListener("click", function(_) {
                if (windowService.isMaximized) {
                    windowService.unmaximize();
                } else {
                    windowService.maximize();
                }
            });
        }
        
        if (btnClose != null) {
            btnClose.addEventListener("click", function(_) {
                // Для закрытия используем прямой вызов, 
                // так как WindowService не должен закрывать сам себя
                js.Browser.window.close();
            });
        }
    }
    
    private function subscribeToEvents():Void {
        // Подписываемся на события изменения состояния окна
        fullscreenUnsub = eventBus.subscribe(FullscreenChanged, function(e:FullscreenChanged) {
            updateMaximizeIcon();
        });
        
        // Также подписываемся на события напрямую от WindowService
        windowService.on(hide.domain.enums.WindowEvent.Maximize, function(_) {
            updateMaximizeIcon();
        });
        
        windowService.on(hide.domain.enums.WindowEvent.Restore, function(_) {
            updateMaximizeIcon();
        });
        
        windowService.on(hide.domain.enums.WindowEvent.Unmaximize, function(_) {
            updateMaximizeIcon();
        });
    }
    
    private function updateMaximizeIcon():Void {
        if (btnMaximize != null) {
            btnMaximize.textContent = windowService.isMaximized ? "❐" : "□";
        }
    }
    
    public function dispose():Void {
        if (fullscreenUnsub != null) {
            fullscreenUnsub.cancel();
        }
    }
}