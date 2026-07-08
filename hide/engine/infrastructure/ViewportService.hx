// hide/engine/infrastructure/ViewportService.hx
package hide.engine.infrastructure;

import h3d.scene.Scene;
import h3d.Camera;
import h3d.mat.Texture;
import hx.injection.Service;
import h3d.pass.ScreenFx;
import hide.engine.infrastructure.shaders.TextureOutputShader;
/**
    Управляет всеми viewport'ами IDE.
    Один движок, много сцен, много RenderTexture.
    Использует ScreenFx для GPU рендеринга RenderTexture в основной canvas engine'а,
    затем CPU blit для копирования в canvas viewport'а.
*/
class ViewportService implements Service {
    private var viewports:Map<String, Viewport>;
    private var screenFx:ScreenFx<TextureOutputShader>;
    public function new() {
        viewports = new Map();
        screenFx = new ScreenFx(new TextureOutputShader());
    }
    
    /**
     * Регистрирует новый viewport (Scene, Shader, Animation, 2D...)
     */
    public function register(id:String, scene:Scene, width:Int, height:Int):Viewport {
        if (viewports.exists(id)) {
            trace('⚠️ Viewport $id already exists, reusing');
            return viewports.get(id);
        }
        
        var vp = new Viewport(id, scene, width, height);
        viewports.set(id, vp);
        trace('✅ Viewport registered: $id (${width}x${height})');
        return vp;
    }
    
    /**
    Рендерит ВСЕ viewport'ы в их RenderTexture, затем выводит на canvas через GPU.
    Вызывается из главного render loop HeapsRenderer.

    Pipeline:
    1. engine.pushTarget(vp.renderTarget) — переключаем вывод на текстуру
    2. engine.clear() — очищаем цвет и глубину
    3. vp.scene.render(engine) — рендерим сцену в текстуру
    4. engine.popTarget() — возвращаем основной таргет
    5. vp.renderToScreen() — GPU blit текстуры на canvas
    */
    public function renderAll(engine:h3d.Engine):Void {
        for (vp in viewports) {
            if (!vp.enabled) continue;
            
            // ✅ 1. Переключаем вывод на текстуру вьюпорта
            engine.pushTarget(vp.renderTarget);
            
            // ✅ 2. ОБЯЗАТЕЛЬНО очищаем цвет и глубину!
            // Без этого сцена рисуется поверх мусора из предыдущего кадра
            engine.clear(0xFF2a2a2a, 1.0, 0); 
            
            // ✅ 3. Рендерим сцену
            vp.scene.render(engine);
            
            // ✅ 4. Возвращаем основной таргет
            engine.popTarget();

            // 5. Копируем в canvas
            // ✅ КОПИРУЕМ ТОЛЬКО ЕСЛИ НУЖНО (например, раз в 10 кадров)
            // ИЛИ вообще не копируем — canvas обновляется сам через WebGL
            // Используем renderToScreen() вместо blitToCanvas()
            // Но пока оставляем fallback на CPU blit для совместимости
            //if (vp.frameCount % 2 == 0) {  // Каждые 10 кадров
            //    vp.blitToCanvas(); // TODO: заменить на vp.renderToScreen(engine)
            //}
            // 5. ✅ GPU-only рендеринг на canvas (без CPU copy!)
            //vp.renderToScreen(engine);
            // 5. ✅ НОВОЕ: Используем ScreenFx для рендеринга RenderTexture в основной canvas
            // Это подготавливает текстуру для GPU blit
            screenFx.shader.texture = vp.renderTarget;
            screenFx.render();
            if (vp.frameCount % 2 == 0) {  // Каждые 10 кадров
                vp.blitToCanvas(); // TODO: заменить на vp.renderToScreen(engine)
            }
            // ✅ Копируем в canvas через GPU (без CPU!)
            //vp.renderToCanvas(engine);
            vp.frameCount++;
        }
    }
    
    public function getViewport(id:String):Null<Viewport> {
        return viewports.get(id);
    }
        // ✅ ДОБАВЛЯЕМ ЭТОТ МЕТОД
    public function resizeAll(width:Int, height:Int):Void {
        for (vp in viewports) {
            vp.resize(width, height);
        }
    }
    public function removeViewport(id:String):Void {
        if (viewports.exists(id)) {
            var vp = viewports.get(id);
            vp.dispose();
            viewports.remove(id);
            trace('🗑️ Viewport removed: $id');
        }
    }
    
    public function dispose():Void {
        for (vp in viewports) vp.dispose();
        viewports.clear();
    }
    /**
     * ✅ НОВОЕ: ресайз конкретного viewport
     */
    public function resizeViewport(id:String, w:Int, h:Int):Void {
        var vp = viewports.get(id);
        if (vp != null) {
            vp.resize(w, h);
        }
    }
}

