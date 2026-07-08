// hide/engine/infrastructure/HeapsEngineManager.hx
package hide.engine.infrastructure;

import h3d.Engine;
import hide.engine.domain.services.IEngineManager;
import hide.engine.domain.services.IEngineEventBus;
import hx.injection.Service;

/**
    Менеджер жизненного цикла Heaps Engine.
    ОТВЕТСТВЕННОСТЬ:
    Создание ОДНОГО экземпляра h3d.Engine
    Запуск ОДНОГО главного render loop (через hxd.System.setLoop)
    Делегирование рендеринга всех viewport'ов в ViewportService
    НЕ ЗНАЕТ:
    Про конкретные сцены, объекты, выделение, обработку мыши
    Про DOM-контейнеры GoldenLayout
    Все viewport'ы (Scene, ShaderPreview, Animation, Game) регистрируются
    в ViewportService и рендерятся в этом общем лупе.
*/
class HeapsEngineManager implements IEngineManager implements Service {
    private var engine:h3d.Engine;
    private var viewportService:ViewportService;
    private var isEngineReady:Bool = false;
    private static var isSystemInitialized:Bool = false;
    private static var instance:Null<HeapsEngineManager> = null;
    
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
            dummyCanvas.width = js.Browser.window.innerWidth;
            dummyCanvas.height = js.Browser.window.innerHeight;
            dummyCanvas.style.position = "absolute";
            dummyCanvas.style.top = "-9999px";
            dummyCanvas.style.left = "-9999px";
            dummyCanvas.style.visibility = "hidden";
            js.Browser.document.body.appendChild(dummyCanvas);
            trace("🎨 [HeapsRenderer] Created hidden #webgl canvas for hxd.Window");
        }
    }
    // ✅ НОВОЕ: метод для обновления размера dummy canvas
    public function updateDummyCanvasSize(width:Int, height:Int):Void {
        var dummyCanvas:js.html.CanvasElement = cast js.Browser.document.getElementById("webgl");
        if (dummyCanvas != null) {
            dummyCanvas.width = width;
            dummyCanvas.height = height;
            trace("📐 [HeapsRenderer] Dummy canvas resized to ${width}x${height}");
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

         // ✅ Логируем поддерживаемые функции (из документации Platform Feature Detection)
        logSupportedFeatures();
        trace("🎨 [HeapsRenderer] Engine ready. Render loop started.");
    }
    
    /**
Логирует поддерживаемые GPU функции для диагностики.
Согласно документации Platform Feature Detection.
*/
private function logSupportedFeatures():Void {
    var driver = @:privateAccess engine.driver;
    if (driver == null) return;
    trace('🔍 [HeapsEngineManager] GPU Features:');
    trace(' -Standard Derivatives: ${driver.hasFeature(StandardDerivatives)}');
    trace(' −FloatTextures:${driver.hasFeature(StandardDerivatives)}' );
    trace(' −FloatTextures:${driver.hasFeature(FloatTextures)}');
    trace(' -Hardware Accelerated: ${driver.hasFeature(HardwareAccelerated)}');
    trace(' −MultipleRenderTargets:${driver.hasFeature(HardwareAccelerated)}');
    trace(' −MultipleRenderTargets:${driver.hasFeature(MultipleRenderTargets)}');
    trace(' - SRGB Textures: ${driver.hasFeature(SRGBTextures)}');
}

    private function mainLoop():Void {
        hxd.Timer.update();
        if (engine != null) {
            viewportService.renderAll(engine);
        }
    }
    
    public function onResize(width:Int, height:Int):Void {
        viewportService.resizeAll(width, height);
            // ✅ Обновляем размер dummy canvas
        updateDummyCanvasSize(width, height);
    }
    
    public function dispose():Void {
        if (engine != null) {
            engine.dispose();
            engine = null;
        }
    }
}