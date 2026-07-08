package hide.engine.infrastructure;

import h3d.mat.Data.TextureFormat;
import h3d.mat.Data.TextureFlags;
import h3d.scene.Scene;
import h3d.mat.Texture;
import js.html.webgl.RenderingContext;
/**
 * Один viewport = сцена + камера + render target + canvas
 */
class Viewport {
    public var id:String;
    public var scene:Scene;
    public var renderTarget:Texture;
    public var canvas:js.html.CanvasElement;
    public var enabled:Bool = true;
    public var width:Int;
    public var height:Int;
    public var renderWidth:Int;
    public var renderHeight:Int;
    public var frameCount:Int = 0;  // ✅ НОВОЕ ПОЛЕ

    public function new(id:String, scene:Scene, width:Int, height:Int) {
        this.id = id;
        this.scene = scene;
        this.width = width;
        this.height = height;
        
        renderWidth = width;
        renderHeight = height;
        // Создаём RenderTexture (GPU-side)
        // ✅ ИСПОЛЬЗУЕМ RGBA32F для лучшего качества (float precision)
        // Или RGBA16U для хорошего качества + производительности
        // ✅ ПРАВИЛЬНО: используем только существующие флаги
        // Target — для render target
        // Dynamic — если часто обновляем (наш случай)
        renderTarget = new Texture(renderWidth, renderHeight, [Target, Dynamic]);
        // ✅ Включаем билинейную фильтрацию для сглаживания
        renderTarget.filter = AnisotropicLinear;
        renderTarget.depthBuffer = new Texture(renderWidth, renderHeight,[], TextureFormat.Depth24Stencil8);
        
        // Создаём canvas для отображения
        canvas = js.Browser.document.createCanvasElement();
        // ✅ Явно задаем внутренние размеры буфера
        canvas.width = width;
        canvas.height = height;
        

        // ✅ ВАЖНО: CSS стили для масштабирования без размытия
        canvas.style.width = "100%";
        canvas.style.height = "100%";
        canvas.style.display = "block";
        canvas.style.objectFit = "contain"; // ← НОВОЕ: сохраняет пропорции
        canvas.style.imageRendering = "auto";  // ← БЫЛО "auto"
        canvas.style.background = "#1a1a1a"; // ← НОВОЕ: фон на случай прозрачности
    }
    
    /**
    GPU-only рендеринг текстуры на canvas через fullscreen quad shader.
    Вызывается из ViewportService после рендеринга сцены в RenderTexture.

    */
    public function renderToScreen(engine:h3d.Engine):Void {
            blitToCanvas();
        frameCount++;
    }

    /**
     * Копирует RenderTexture → Canvas (пока через CPU)
     *
     * Fallback: CPU blit (используется только если GPU blit недоступен).
    */
    public function blitToCanvas():Void {

        // ✅ Blit раз в 2 кадра для плавности
        /*if (frameCount % 2 != 0) {
            frameCount++;
            return;
        }*/
        var pixels = renderTarget.capturePixels();
    
        // ✅ Диагностика: проверяем, есть ли реальные данные
        if (pixels == null || pixels.bytes.length == 0) {
            trace('⚠️ [Viewport $id] capturePixels returned EMPTY data!');
            return;
        }
        
        var ctx = canvas.getContext("2d");
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";
        if (ctx == null) {
            trace('⚠️ [Viewport $id] Canvas 2D context is NULL!');
            return;
        }

        var imageData = ctx.createImageData(width, height);
        var bytes = pixels.bytes;
        var data = imageData.data;
        
        var len = width * height;
        // ✅ Оптимизированная конвертация BGRA → RGBA
        var i = 0;
        while (i < len) {
            var srcIdx = i << 2;  // i * 4 (bit shift быстрее)
            var dstIdx = i << 2;
            data[dstIdx]     = bytes.get(srcIdx + 2); // R
            data[dstIdx + 1] = bytes.get(srcIdx + 1); // G
            data[dstIdx + 2] = bytes.get(srcIdx);     // B
            data[dstIdx + 3] = bytes.get(srcIdx + 3); // A
            i++;
        }
        
        ctx.putImageData(imageData, 0, 0);
        // ✅ Рисуем высококачественную текстуру, браузер сам масштабирует с сглаживанием
        // Создаём временный canvas для масштабирования
        var tempCanvas = js.Browser.document.createCanvasElement();
        tempCanvas.width = renderWidth;
        tempCanvas.height = renderHeight;
        var tempCtx = tempCanvas.getContext("2d");
        tempCtx.putImageData(imageData, 0, 0);
        
        // ✅ Рисуем с масштабированием (браузер использует imageSmoothingQuality)
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(tempCanvas, 0, 0, width, height);
        // ✅ Временная рамка для диагностики
        ctx.strokeStyle = "#00ff00";
        ctx.lineWidth = 3;
        ctx.strokeRect(0, 0, width, height);
            // ✅ ОТЛАДКА: Рисуем текст
        ctx.fillStyle = "#00ff00";
        ctx.font = "20px monospace";
        ctx.fillText("VIEWPORT ACTIVE", 10, 30);
    }
    
    public function resize(w:Int, h:Int):Void {
        if (w < 1) w = 1;
        if (h < 1) h = 1;
        
        width = w;
        height = h;
        canvas.width = w;
        canvas.height = h;
        
        renderTarget.dispose();
        renderTarget = new Texture(w, h, [Target, Dynamic]);
        renderTarget.depthBuffer = new Texture(w, h, [], TextureFormat.Depth24Stencil8);
        
        // Обновляем камеру под новый aspect ratio
        if (scene != null) {
            scene.camera.screenRatio = w / h;
            scene.camera.update();
        }
    }
    
    public function dispose():Void {
        renderTarget.dispose();
        if (canvas != null && canvas.parentElement != null) {
            canvas.parentElement.removeChild(canvas);
        }
    }
}