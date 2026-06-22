// engine/infrastructure/ShaderPreviewRenderer.hx
package hide.engine.infrastructure;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Sphere;
import hx.injection.Service;

/**
 * Отвечает ТОЛЬКО за превью шейдера на сфере.
 * Не знает ничего про React, ноды, IDE.
 */
class ShaderPreviewRenderer implements Service {
    private var engine:h3d.Engine;
    private var s3d:h3d.scene.Scene;
    private var previewMesh:Null<Mesh>;
    private var canvas:js.html.CanvasElement;
    private var container:Dynamic;
    
    private static var isInitialized:Bool = false;
    
    public function new() {}
    
    /**
     * Инициализирует превью в указанном DOM-контейнере.
     * Вызывается из IDE-слоя (ShaderEditorPanel).
     */
    public function init(container:Dynamic):Void {
        this.container = container;
        
        // Создаём canvas
        canvas = js.Browser.document.createCanvasElement();
        canvas.width = 400;
        canvas.height = 300;
        canvas.style.cssText = 'width:100%;height:100%;background:#000;';
        
        if (container != null && container.appendChild != null) {
            container.appendChild(canvas);
        }
        
        initEngine();
    }
    
    private function initEngine():Void {
        var existingEngine = h3d.Engine.getCurrent();
        
        if (existingEngine != null) {
            this.engine = existingEngine;
            onEngineReady();
        } else {
            if (!isInitialized) {
                hxd.System.start(function() {
                    this.engine = @:privateAccess new h3d.Engine();
                    engine.onReady = onEngineReady;
                    engine.init();
                    isInitialized = true;
                });
            } else {
                this.engine = @:privateAccess new h3d.Engine();
                engine.onReady = onEngineReady;
                engine.init();
            }
        }
    }
    
    private function onEngineReady():Void {
        s3d = new h3d.scene.Scene();
        s3d.renderer.shadows = false;
        @:privateAccess s3d.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix() // пустая матрица
        );
        // Камера
        var camera = s3d.camera;
        camera.pos.set(0, 2, 3);
        camera.target.set(0, 0, 0);
        camera.fovY = 45;
        camera.zNear = 0.1;
        camera.zFar = 100;
        camera.update();
        
        // Свет
        var light = new DirLight(new h3d.Vector(-0.5, -0.5, -1), s3d);
        
        // Сфера для превью
        var sphere = new Sphere(1, 32, 32);
        sphere.addNormals();
        sphere.addUVs();
        previewMesh = new Mesh(sphere, s3d);
        previewMesh.material.color.setColor(0xFFFFFF);
        
        // Запускаем рендер-луп
        hxd.System.setLoop(mainLoop);
        
        trace("✅ [ShaderPreview] Initialized");
    }
    
    private function mainLoop():Void {
        hxd.Timer.update();
        if (engine != null && s3d != null) {
            // Медленное вращение сферы
            if (previewMesh != null) {
                previewMesh.rotate(0, 0.01,0);
            }
            engine.render(s3d);
        }
    }
    
    /**
     * Обновляет материал сферы на основе сгенерированного шейдера.
     * Вызывается из ShaderEditorService при изменении графа.
     */
    public function updateMaterial(shaderData:Dynamic):Void {
        if (previewMesh == null) return;
        
        // TODO: компилируем HXSL из shaderData
        // и применяем к previewMesh.material
        
        trace("🎨 [ShaderPreview] Material updated");
    }
    
    public function dispose():Void {
        if (s3d != null) {
            s3d.dispose();
            s3d = null;
        }
        if (canvas != null && canvas.parentElement != null) {
            canvas.parentElement.removeChild(canvas);
            canvas = null;
        }
    }
}