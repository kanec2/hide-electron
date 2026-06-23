package hide.engine.infrastructure;

import h3d.scene.Scene;
import h3d.mat.Texture;

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
    
    public function new(id:String, scene:Scene, width:Int, height:Int) {
        this.id = id;
        this.scene = scene;
        this.width = width;
        this.height = height;
        
        // Создаём RenderTexture (GPU-side)
        renderTarget = new Texture(width, height, [Target]);
        renderTarget.depthBuffer = new Texture(width, height, Depth24Stencil8);
        
        // Создаём canvas для отображения
        canvas = js.Browser.document.createCanvasElement();
        // ✅ Явно задаем внутренние размеры буфера
        canvas.width = width;
        canvas.height = height;
        
        // ✅ Стили для отображения
        canvas.style.width = "100%";
        canvas.style.height = "100%";
        canvas.style.display = "block";
    }
    
    /**
     * Копирует RenderTexture → Canvas (пока через CPU)
     */
    public function blitToCanvas():Void {
        var pixels = renderTarget.capturePixels();
    
        // ✅ Диагностика: проверяем, есть ли реальные данные
        if (pixels == null || pixels.bytes.length == 0) {
            trace('⚠️ [Viewport $id] capturePixels returned EMPTY data!');
            return;
        }
        
        var ctx = canvas.getContext("2d");
        if (ctx == null) {
            trace('⚠️ [Viewport $id] Canvas 2D context is NULL!');
            return;
        }

        var imageData = ctx.createImageData(width, height);
        var bytes = pixels.bytes;
        var data = imageData.data;
        
        var len = width * height * 4;
        for (i in 0...len) {
            data[i] = bytes.get(i);
        }
        
        ctx.putImageData(imageData, 0, 0);
        
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
        width = w;
        height = h;
        canvas.width = w;
        canvas.height = h;
        renderTarget.dispose();
        renderTarget = new Texture(w, h, [Target]);
        renderTarget.depthBuffer = new Texture(w, h, Depth24Stencil8);
    }
    
    public function dispose():Void {
        renderTarget.dispose();
        if (canvas != null && canvas.parentElement != null) {
            canvas.parentElement.removeChild(canvas);
        }
    }
}