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
        canvas.width = width;
        canvas.height = height;
    }
    
    /**
     * Копирует RenderTexture → Canvas (пока через CPU)
     */
    public function blitToCanvas():Void {
        var pixels = renderTarget.capturePixels();
        var ctx = canvas.getContext("2d");
        if (ctx == null) return;
        
        var imageData = ctx.createImageData(width, height);
        var bytes = pixels.bytes; // ✅ Получаем байты из hxd.Pixels
        var data = imageData.data;
        
        // Копируем байты. Heaps обычно возвращает RGBA.
        // Если цвета будут инвертированы (синий вместо красного), поменяй местами R и B ниже.
        var len = width * height * 4;
        for (i in 0...len) {
            data[i] = bytes.get(i);
        }
        
        ctx.putImageData(imageData, 0, 0);
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