// hide/engine/infrastructure/HeapsRenderer.hx
package hide.engine.infrastructure;

import h3d.Engine;
import hide.engine.domain.services.IRenderer;
import hide.engine.domain.services.IEngineEventBus;
import hx.injection.Service;

/**
 * Менеджер движка Heaps.
 * Создаёт ОДИН h3d.Engine и ОДИН render loop.
 * НЕ знает ничего о сценах, объектах, выделении или мыши.
 */
class HeapsRenderer implements IRenderer implements Service {
    private var engine:h3d.Engine;
    private var viewportService:ViewportService;
    private var isEngineReady:Bool = false;
    private static var isSystemInitialized:Bool = false;
    
    public function new(viewportService:ViewportService) {
        this.viewportService = viewportService;
    }
    
    public function init():Void {
        // ✅ ШАГ 1: Создаём скрытый canvas #webgl для hxd.Window и h3d.Engine
        ensureDummyCanvas();
        
        // ✅ ШАГ 2: Инициализируем движок
        initEngine();
    }

    private function ensureDummyCanvas():Void {
        if (js.Browser.document.getElementById("webgl") == null) {
            var dummyCanvas = js.Browser.document.createCanvasElement();
            dummyCanvas.id = "webgl";
            dummyCanvas.width = 16;
            dummyCanvas.height = 16;
            dummyCanvas.style.position = "absolute";
            dummyCanvas.style.top = "-9999px";
            dummyCanvas.style.left = "-9999px";
            dummyCanvas.style.visibility = "hidden";
            js.Browser.document.body.appendChild(dummyCanvas);
            trace("🎨 [HeapsRenderer] Created hidden #webgl canvas for hxd.Window");
        }
    }

    private function initEngine():Void {
        Engine.ANTIALIASING = 4;
        var existingEngine = h3d.Engine.getCurrent();
        if (existingEngine != null) {
            trace("🎨 [HeapsRenderer] Using existing engine");
            this.engine = existingEngine;
            // ✅ ВАЖНО: если engine уже создан, но driver ещё null, ждём
            if (@:privateAccess engine.driver != null) {
                onEngineReady();
            } else {
                haxe.Timer.delay(onEngineReady, 0);
            }
        } else {
            if (!isSystemInitialized) {
                hxd.System.start(function() {
                    this.engine = @:privateAccess new h3d.Engine();
                    engine.onReady = onEngineReady;
                    engine.init();
                    isSystemInitialized = true;
                });
            } else {
                this.engine = @:privateAccess new h3d.Engine();
                engine.onReady = onEngineReady;
                engine.init();
            }
        }
    }
    
    private function onEngineReady():Void {
        // ✅ ЗАЩИТА: ждём, пока driver действительно готов
        if (engine == null || @:privateAccess engine.driver == null) {
            trace("⏳ [HeapsRenderer] Engine created but driver not ready, retrying...");
            haxe.Timer.delay(onEngineReady, 50);
            return;
        }
        
        hxd.System.setLoop(mainLoop);
        engine.backgroundColor = 0xFF2a2a2a;
        isEngineReady = true;
        trace("🎨 [HeapsRenderer] Engine ready. Render loop started.");
    }
    
    private function mainLoop():Void {
        hxd.Timer.update();
        if (engine != null) {
            viewportService.renderAll(engine);
        }
    }
    
    public function onResize(width:Int, height:Int):Void {
        viewportService.resizeAll(width, height);
    }
    
    public function dispose():Void {
        if (engine != null) {
            engine.dispose();
            engine = null;
        }
    }
}