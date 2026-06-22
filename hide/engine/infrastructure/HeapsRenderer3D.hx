// hide/engine/infrastructure/HeapsRenderer3D.hx
package hide.engine.infrastructure;

/**
 * Кастомный 3D-рендерер для Heaps.
 * Аналог hide.Renderer из legacy Hide IDE.
 * 
 * Ключевое отличие от стандартного h3d.scene.fwd.Renderer:
 * - Проверяет has("shadow") перед рендером теней
 * - Управляет passes в правильном порядке
 * - Это решает проблему "Missing global value shadow.proj"
 */
class HeapsRenderer3D extends h3d.scene.fwd.Renderer {
    public function new() {
        super();
    }
    
    override function render() {
        // 1. Создаём render target
        var output = allocTarget("output");
        setTarget(output);
        clear(engine.backgroundColor, 1, 0);
        
        // 2. Shadow pass (ТОЛЬКО если есть объекты с тенями!)
        // ← ЭТО КЛЮЧЕВОЕ! Без этой проверки шейдер требует shadow.proj
        if (has("shadow"))
            renderPass(shadow, get("shadow"));
        
        // 3. Depth pass
        if (has("depth"))
            renderPass(depth, get("depth"));
        
        // 4. Normal pass
        if (has("normal"))
            renderPass(normal, get("normal"));
        
        // 5. Основной pass (непрозрачные объекты)
        renderPass(defaultPass, get("default"), frontToBack);
        
        // 6. Прозрачные объекты (от дальних к ближним)
        renderPass(defaultPass, get("alpha"), backToFront);
        
        // 7. Аддитивные объекты
        renderPass(defaultPass, get("additive"));
        
        // 8. Overlay
        renderPass(defaultPass, get("overlay"), backToFront);
        
        // 9. UI (поверх всего)
        renderPass(defaultPass, get("ui"), backToFront);
        
        // 10. Сброс target
        resetTarget();
    }
}