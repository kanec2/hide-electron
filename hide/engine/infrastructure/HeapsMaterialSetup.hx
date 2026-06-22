// hide/engine/infrastructure/HeapsMaterialSetup.hx
package hide.engine.infrastructure;

/**
 * Кастомный MaterialSetup для Heaps.
 * Аналог hide.MaterialSetup из legacy Hide IDE, но без зависимостей от legacy.
 * 
 * Управляет тем, какой Renderer используется для рендера сцены.
 */
class HeapsMaterialSetup extends h3d.mat.MaterialSetup {
    public function new() {
        super("Default");
    }
    
    override public function createRenderer():h3d.scene.Renderer {
        return new HeapsRenderer3D();
    }
    
    override function getDefaults(?type:String):Any {
        if (type == "ui") return {
            kind: "Alpha",
            shadows: false,
            culled: false,
            lighted: false
        };
        return super.getDefaults(type);
    }
}