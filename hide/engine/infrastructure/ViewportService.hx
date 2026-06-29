// hide/engine/infrastructure/ViewportService.hx
package hide.engine.infrastructure;

import h3d.scene.Scene;
import h3d.Camera;
import h3d.mat.Texture;
import hx.injection.Service;

/**
 * Управляет всеми viewport'ами IDE.
 * Один движок, много сцен, много RenderTexture.
 */
class ViewportService implements Service {
    private var viewports:Map<String, Viewport>;
    
    public function new() {
        viewports = new Map();
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
     * Рендерит ВСЕ viewport'ы в их RenderTexture.
     * Вызывается из главного render loop HeapsRenderer.
     */
    public function renderAll(engine:h3d.Engine):Void {
        for (vp in viewports) {
            if (!vp.enabled) continue;
            
            // ✅ 1. Переключаем вывод на текстуру вьюпорта
            engine.pushTarget(vp.renderTarget);
            
            // ✅ 2. ОБЯЗАТЕЛЬНО очищаем цвет и глубину!
            // Без этого сцена рисуется поверх мусора из предыдущего кадра
            engine.clear(0xFF2a2a2a, 1.0); 
            
            // ✅ 3. Рендерим сцену
            vp.scene.render(engine);
            
            // ✅ 4. Возвращаем основной таргет
            engine.popTarget();

            // 5. Копируем в canvas
            // ✅ КОПИРУЕМ ТОЛЬКО ЕСЛИ НУЖНО (например, раз в 10 кадров)
            // ИЛИ вообще не копируем — canvas обновляется сам через WebGL
            // Если нужно именно blit — делайте реже:
            if (vp.frameCount % 10 == 0) {  // Каждые 10 кадров
                vp.blitToCanvas();
            }
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

