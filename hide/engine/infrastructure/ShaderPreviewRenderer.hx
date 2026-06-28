// engine/infrastructure/ShaderPreviewRenderer.hx
package hide.engine.infrastructure;

import h3d.scene.pbr.Renderer;
import h3d.shader.pbr.PropsValues;
import h3d.scene.pbr.Environment;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Sphere;
import hx.injection.Service;

class ShaderPreviewRenderer implements Service {
    // ✅ УБРАНО: private var engine:h3d.Engine;
    private var s3d:h3d.scene.Scene;
    private var previewMesh:Null<Mesh>;
    private var pbrValues:Null<PropsValues>;
    private var env:Null<Environment>;
    // ✅ НОВОЕ: публичный доступ к сцене для регистрации во ViewportService
    public var scene(get, never):h3d.scene.Scene;
    private function get_scene():h3d.scene.Scene return s3d;

    // ✅ НОВОЕ: храним текущие параметры
    private var currentShaderData:ShaderData;

    public function new() {
        // ✅ ВАЖНО: устанавливаем PBR MaterialSetup ДО создания сцены
        h3d.mat.MaterialSetup.current = new h3d.mat.PbrMaterialSetup();
    }

    /**
     * Инициализирует ТОЛЬКО сцену и объекты.
     * НЕ создает движок и НЕ запускает луп!
     */
    public function init():Void {
        if (s3d != null) return; // Уже инициализировано

        s3d = new h3d.scene.Scene();
        s3d.renderer.shadows = false;

        // ✅ Настраиваем PBR Renderer
        var renderer:Renderer = cast(s3d.renderer, Renderer);
        
        // ✅ Создаём минимальный Environment (белый cubemap для базового освещения)
        var envMap = new h3d.mat.Texture(256, 256, [Cube]);
        // Заполняем все 6 граней белым цветом
        for (face in 0...6) {
            var pixels = hxd.Pixels.alloc(256, 256, h3d.mat.Texture.nativeFormat);
            for (i in 0...pixels.width * pixels.height) {
                pixels.setPixel(i % pixels.width, Std.int(i / pixels.width), 0xFFFFFFFF);
            }
            envMap.uploadPixels(pixels, 0, face);
        }
        
        env = new Environment(envMap);
        env.compute();
        renderer.env = env;

        // Заглушка для теней (как в SceneViewportController)
        @:privateAccess s3d.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix()
        );
        // ✅ Добавьте больше источников света
        var dirLight = new DirLight(new h3d.Vector(-0.5, -0.5, -1), s3d);
        dirLight.enableSpecular = true;
        dirLight.color.set(1, 1, 1);

        // Камера
        var camera = s3d.camera;
        camera.pos.set(0, 2, 4);  // Чуть дальше
        camera.target.set(0, 0, 0);
        camera.fovY = 60;  // Шире угол
        camera.zNear = 0.1;
        camera.zFar = 100;
        camera.update();

        // Свет
        // ✅ PBR Point Light вместо DirLight
        var light = new h3d.scene.pbr.PointLight(s3d);
        light.setPosition(3, 2, 4);
        light.range = 20;
        light.power = 2;


         // Сфера для превью
        var sphere = new Sphere(1, 64, 64);
        sphere.addNormals();
        sphere.addUVs();
        previewMesh = new Mesh(sphere, s3d);
        
        // ✅ Добавляем PBR PropsValues шейдер (metalness, roughness)
        pbrValues = new PropsValues(0.0, 0.5); // metalness=0, roughness=0.5
        previewMesh.material.mainPass.addShader(pbrValues);
        
        // Базовый цвет (albedo)
        previewMesh.material.color.set(0.8, 0.8, 0.8);
        
        trace("✅ [ShaderPreview] PBR Scene initialized");
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
    /**
     * Обновляет PBR-материал сферы.
     */
    public function updateMaterial(shaderData:Dynamic):Void {
        if (previewMesh == null || pbrValues == null) return;
        
        // Albedo (базовый цвет)
        if (shaderData.albedo != null) {
            if (isVec3(shaderData.albedo)) {
                previewMesh.material.color.set(
                    shaderData.albedo.x,
                    shaderData.albedo.y,
                    shaderData.albedo.z
                );
            } else if (Std.is(shaderData.albedo, Float)) {
                // Если пришло число — используем как grayscale
                var v:Float = shaderData.albedo;
                previewMesh.material.color.set(v, v, v);
            }
        } else {
            // Дефолт: серый
            previewMesh.material.color.set(0.5, 0.5, 0.5);
        }
        
        // Metalness
        if (shaderData.metallic != null && Std.is(shaderData.metallic, Float)) {
            pbrValues.metalnessValue = shaderData.metallic;
        } else {
            pbrValues.metalnessValue = 0.0;
        }
        
        // Roughness
        if (shaderData.roughness != null && Std.is(shaderData.roughness, Float)) {
            pbrValues.roughnessValue = shaderData.roughness;
        } else {
            pbrValues.roughnessValue = 0.5;
        }
        
        // Emissive (если есть)
        if (shaderData.emissive != null && isVec3(shaderData.emissive)) {
            // В PBR emissive обычно через отдельный шейдер, но для простоты:
            // можно добавить h3d.shader.pbr.Emissive если нужно
        }
        
        trace('🎨 [ShaderPreview] PBR Updated: albedo=(${previewMesh.material.color.x}, ${previewMesh.material.color.y}, ${previewMesh.material.color.z}), ' +
              'metalness=${pbrValues.metalnessValue}, roughness=${pbrValues.roughnessValue}');
    }
    private function isVec3(v:Dynamic):Bool {
        return v != null && Reflect.hasField(v, "x") && Reflect.hasField(v, "y") && Reflect.hasField(v, "z");
    }
    public function dispose():Void {
        if (s3d != null) {
            s3d.dispose();
            s3d = null;
        }
        previewMesh = null;
        pbrValues = null;
        env = null;
    }
}