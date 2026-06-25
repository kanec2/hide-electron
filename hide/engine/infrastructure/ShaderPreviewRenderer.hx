// engine/infrastructure/ShaderPreviewRenderer.hx
package hide.engine.infrastructure;

import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Sphere;
import hx.injection.Service;

class ShaderPreviewRenderer implements Service {
    // ✅ УБРАНО: private var engine:h3d.Engine;
    private var s3d:h3d.scene.Scene;
    private var previewMesh:Null<Mesh>;
    
    // ✅ НОВОЕ: публичный доступ к сцене для регистрации во ViewportService
    public var scene(get, never):h3d.scene.Scene;
    private function get_scene():h3d.scene.Scene return s3d;

    // ✅ НОВОЕ: храним текущие параметры
    private var currentShaderData:ShaderData;

    public function new() {}

    /**
     * Инициализирует ТОЛЬКО сцену и объекты.
     * НЕ создает движок и НЕ запускает луп!
     */
    public function init():Void {
        if (s3d != null) return; // Уже инициализировано

        s3d = new h3d.scene.Scene();
        s3d.renderer.shadows = false;
        
        // Заглушка для теней (как в SceneViewportController)
        @:privateAccess s3d.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix()
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
        new DirLight(new h3d.Vector(-0.5, -0.5, -1), s3d);

        // Сфера для превью
        var sphere = new Sphere(1, 32, 32);
        sphere.addNormals();
        sphere.addUVs();
        previewMesh = new Mesh(sphere, s3d);
        previewMesh.material.color.setColor(0xFFFFFF);
        previewMesh.material.mainPass.enableLights = true;
        previewMesh.material.getPass("shadow").isStatic = true;

        var color = new h3d.Vector(Math.random(), Math.random(), Math.random());
        color.normalize();
        previewMesh.material.color.set(color.x, color.y, color.z);


        trace("✅ [ShaderPreview] Scene initialized (no engine created)");
    }
    /**
     * Применяет скомпилированные данные графа к материалу.
     * Вызывается из React-компонента при изменении графа.
     */
    public function applyShaderData(data:ShaderData):Void {
        if (previewMesh == null || data == null) return;
        
        currentShaderData = data;
        
        // 1. Albedo (цвет)
        previewMesh.material.color.set(data.albedo.x, data.albedo.y, data.albedo.z);
        
        // 2. Metallic и Roughness через шейдерные uniform'ы
        // В Heaps это делается через custom shader (см. ниже)
        
        trace('🎨 [ShaderPreview] Applied: albedo=(${data.albedo.x}, ${data.albedo.y}, ${data.albedo.z}), ' +
              'metallic=${data.metallic}, roughness=${data.roughness}');
    }
    /**
     * Обновляет материал сферы.
     * Вызывается из React-компонента при изменении графа.
     */
    public function updateMaterial(shaderData:Dynamic):Void {
        if (previewMesh == null) return;
        // TODO: применение шейдера
        trace("🎨 [ShaderPreview] Material updated");
    }

    public function dispose():Void {
        if (s3d != null) {
            s3d.dispose();
            s3d = null;
        }
        previewMesh = null;
    }
}