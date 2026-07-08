// engine/infrastructure/ShaderPreviewRenderer.hx
package hide.engine.infrastructure;

import h3d.mat.Data.Face;
import h3d.scene.pbr.Renderer;
import h3d.shader.pbr.PropsValues;
import h3d.scene.pbr.Environment;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Sphere;
import hide.engine.domain.services.IResourceLoader; // ← ДОБАВИТЬ
import hx.injection.Service;
import hide.engine.infrastructure.shaders.*;

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

    // ✅ Orbit Camera параметры
    private var theta:Float = 0.5;      // Горизонтальный угол (yaw)
    private var phi:Float = 0.3;        // Вертикальный угол (pitch)
    private var distance:Float = 3.5;   // Расстояние от центра
    private var isDragging:Bool = false;
    private var lastMouseX:Float = 0;
    private var lastMouseY:Float = 0;
    
    // ✅ Ограничения
    private var minDistance:Float = 1.5;
    private var maxDistance:Float = 10.0;
    private var minPhi:Float = -1.5;    // ~-86 градусов
    private var maxPhi:Float = 1.5;     // ~86 градусов
    private var resourceLoader:IResourceLoader; // ← ДОБАВИТЬ
    private var albedoTexture:Null<h3d.mat.Texture> = null;
    private var normalTexture:Null<h3d.mat.Texture> = null;
    // ✅ МОДИФИКАТОРЫ (вместо UniversalPbrShader!)
    private var albedoModifier:Null<AlbedoTextureModifier> = null;
    private var normalModifier:Null<NormalMapModifier> = null;
    private var emissiveModifier:Null<EmissiveModifier> = null;

    public function new(resourceLoader:IResourceLoader) {
        this.resourceLoader = resourceLoader;
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
        
        // ✅ ПРОСТОЙ ENVIRONMENT — быстро создаётся
        // ✅ БЫСТРАЯ инициализация БЕЗ env.compute()
        // Environment создадим асинхронно ПОЗЖЕ
        env = null;
    

        // Заглушка для теней
        @:privateAccess s3d.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix()
        );
       
        // ✅ Добавьте больше источников света
        // ✅ ОСВЕЩЕНИЕ — 2 источника
        /*var dirLight = new DirLight(new h3d.Vector(-0.5, -0.8, -0.3), s3d);
        dirLight.enableSpecular = true;
        dirLight.color.set(1.0, 1.0, 1.0);

        var fillLight = new DirLight(new h3d.Vector(0.5, 0.3, 0.5), s3d);
        fillLight.enableSpecular = false;
        fillLight.color.set(0.3, 0.3, 0.35);*/
        var light = new h3d.scene.pbr.PointLight(s3d);
        light.setPosition(10, 10, 10);  // Дальше от сферы
        light.range = 50;
        light.power = 2;

        // Камера
        var camera = s3d.camera;
        // Убедись, что камера смотрит правильно
        s3d.camera.pos.set(0, 0, 5);
        s3d.camera.target.set(0, 0, 0);
        s3d.camera.up.set(0, 1, 0);  // ✅ Явно установи up вектор
        s3d.camera.update();

        // ✅ Начальная позиция камеры через orbit параметры
        updateCameraPosition();
        // Свет
        // ✅ PBR Point Light вместо DirLight
        /*var light = new h3d.scene.pbr.PointLight(s3d);
        light.setPosition(3, 2, 4);
        light.range = 20;
        light.power = 2;*/


         // Сфера для превью
        // ✅ СФЕРА — МЕНЬШЕ СЕГМЕНТОВ (быстрее загрузка)
        // Было: new Sphere(1, 32, 32) или 64,64
        // ✅ Сделай больше:
        var sphere = new Sphere(1, 32, 32);  // 128 сегментов по ширине и высоте
        sphere.addNormals();
        sphere.addUVs();
        // ✅ Добавь тангенсы для правильного PBR
        sphere.addTangents();
        previewMesh = new Mesh(sphere, s3d);
        
        pbrValues = new PropsValues(0.0, 0.5);
        previewMesh.material.mainPass.addShader(pbrValues);
        previewMesh.material.color.set(0.8, 0.8, 0.8);
        previewMesh.material.mainPass.enableLights = true;
        previewMesh.material.mainPass.setPassName("default");
        previewMesh.material.mainPass.culling = Face.None;
        
        trace("✅ [ShaderPreview] PBR Scene initialized (FAST)");

        // ✅ АСИНХРОННО создаём environment через 100мс (не блокирует UI!)
        haxe.Timer.delay(function() {
            initEnvironmentAsync();
        }, 100);
    }
    /**
     * ✅ АСИНХРОННАЯ инициализация environment
     * Вызывается после того, как UI уже отрисовался
     */
    private function initEnvironmentAsync():Void {
        if (env != null) return;
        
        trace("⏳ [ShaderPreview] Creating environment async...");
        
        var size = 512;
        var envMap = createEnvMap();
        
        env = new Environment(envMap);
        env.compute();  // ← Тяжёлая операция, но теперь она НЕ блокирует открытие
        
        var renderer:Renderer = cast(s3d.renderer, Renderer);
        renderer.env = env;
        env.power = 1.0;  // ✅ Настраиваем яркость через environment
        //cast(s3d.lightSystem, h3d.scene.fwd.LightSystem).ambientLight.set(0.5, 0.5, 0.5);
        trace("✅ [ShaderPreview] Environment ready");
    }

    
    /**
     * ✅ ПРОСТОЙ environment — серый градиент
     * Создаётся БЫСТРО (небольшая текстура)
     */
    private function createEnvMap():h3d.mat.Texture {
        // ✅ 512x512 вместо 256x256
        var envMap = new h3d.mat.Texture(256, 256, [Cube]);
    
        // Заполни белым/серым цветом (нейтральное освещение)
        inline function set(face:Int, res:hxd.res.Image) {
			var pix = res.getPixels();
			envMap.uploadPixels(pix, 0, face);
		}
		set(0, hxd.Res.front);
		set(1, hxd.Res.back);
		set(2, hxd.Res.right);
		set(3, hxd.Res.left);
		set(4, hxd.Res.top);
		set(5, hxd.Res.bottom);
        
        return envMap;
    }
    /**
     * ✅ НОВОЕ: Подключает управление камерой к canvas
     * Вызывается из ShaderEditorPanel после регистрации viewport
     */
    public function setupOrbitControls(canvas:js.html.CanvasElement):Void {
        trace("🎮 [ShaderPreview] Setting up orbit controls");
        
        // Mouse down - начало вращения
        canvas.addEventListener("mousedown", function(e:js.html.MouseEvent) {
            if (e.button == 0) { // Только левая кнопка
                isDragging = true;
                lastMouseX = e.clientX;
                lastMouseY = e.clientY;
                canvas.style.cursor = "grabbing";
            }
        });
        
        // Mouse move - вращение
        canvas.addEventListener("mousemove", function(e:js.html.MouseEvent) {
            if (!isDragging) return;
            
            var dx = e.clientX - lastMouseX;
            var dy = e.clientY - lastMouseY;
            
            // Чувствительность вращения
            var sensitivity = 0.01;
            theta -= dx * sensitivity;
            phi += dy * sensitivity;
            
            // Ограничиваем phi чтобы не было gimbal lock
            phi = Math.max(minPhi, Math.min(maxPhi, phi));
            
            lastMouseX = e.clientX;
            lastMouseY = e.clientY;
            
            updateCameraPosition();
        });
        
        // Mouse up - конец вращения
        canvas.addEventListener("mouseup", function(e:js.html.MouseEvent) {
            isDragging = false;
            canvas.style.cursor = "grab";
        });
        
        // Mouse leave - сброс dragging
        canvas.addEventListener("mouseleave", function(e:js.html.MouseEvent) {
            isDragging = false;
            canvas.style.cursor = "grab";
        });
        
        // Wheel - зум
        canvas.addEventListener("wheel", function(e:js.html.WheelEvent) {
            e.preventDefault();
            
            var zoomSpeed = 0.005;
            distance += e.deltaY * zoomSpeed;
            distance = Math.max(minDistance, Math.min(maxDistance, distance));
            
            updateCameraPosition();
        }, { passive: false });
        
        // Начальный курсор
        canvas.style.cursor = "grab";
        
        trace("✅ [ShaderPreview] Orbit controls attached");
    }

    /**
     * ✅ Обновляет позицию камеры на основе theta, phi, distance
     */
    private function updateCameraPosition():Void {
        if (s3d == null) return;
        
        var cam = s3d.camera;
        
        // Сферические → Декартовы координаты
        var x = distance * Math.cos(phi) * Math.sin(theta);
        var y = distance * Math.sin(phi);
        var z = distance * Math.cos(phi) * Math.cos(theta);
        
        cam.pos.set(x, y, z);
        cam.target.set(0, 0, 0); // Смотрим в центр (где сфера)
        cam.update();
    }

    // Добавьте новый метод:
    /**
     * Загружает текстуру и применяет к материалу сферы.
     * Вызывается из ShaderEditorPanel при наличии ноды texture/sample.
     */
    /**
     * ✅ ОБНОВЛЁННЫЙ метод загрузки текстуры через IResourceLoader
     */
    public function setAlbedoTexture(path:String):Void {
        // Загружаем текстуру
        var res = hxd.res.Loader.currentInstance.load(path);
        var tex = res.toTexture();
        
        // Создаём или обновляем модификатор
        if (albedoModifier == null) {
            albedoModifier = new AlbedoTextureModifier();
            previewMesh.material.mainPass.addShader(albedoModifier);
        }
        
        // Устанавливаем текстуру в шейдер
        previewMesh.material.texture = tex;
        
        trace('🖼️ [ShaderPreview] Albedo texture applied via modifier');
    }
    /**
     * ✅ НОВОЕ: устанавливает normal map через модификатор
     */
    public function setNormalTexture(path:String, strength:Float = 1.0):Void {
        if (normalTexture != null) {
            normalTexture.dispose();
            normalTexture = null;
        }
        
        if (path == null || path == "") {
            // Удаляем модификатор
            if (normalModifier != null) {
                previewMesh.material.mainPass.removeShader(normalModifier);
                normalModifier = null;
            }
            trace('🔵 [ShaderPreview] Normal map cleared');
            return;
        }
        
        try {
            var res = hxd.res.Loader.currentInstance.load(path);
            normalTexture = res.toTexture();
            
            // Создаём модификатор, если его нет
            if (normalModifier == null) {
                normalModifier = new NormalMapModifier();
                previewMesh.material.mainPass.addShader(normalModifier);
            }
            
            // Устанавливаем текстуру и силу
            previewMesh.material.normalMap = normalTexture;
            normalModifier.normalStrength = strength;
            
            trace('🔵 [ShaderPreview] Normal map applied: $path (strength=$strength)');
        } catch (e:Dynamic) {
            trace('❌ [ShaderPreview] Failed to load normal texture: $e');
        }
    }
    
    /**
     * ✅ НОВОЕ: устанавливает emissive через модификатор
     */
    public function setEmissive(color:h3d.Vector, intensity:Float):Void {
        if (intensity <= 0) {
            if (emissiveModifier != null) {
                previewMesh.material.mainPass.removeShader(emissiveModifier);
                emissiveModifier = null;
            }
            return;
        }
        
        if (emissiveModifier == null) {
            emissiveModifier = new EmissiveModifier();
            previewMesh.material.mainPass.addShader(emissiveModifier);
        }
        
        emissiveModifier.emissiveColor.set(color.x, color.y, color.z);
        emissiveModifier.emissiveIntensity = intensity;
        
        trace('💡 [ShaderPreview] Emissive applied: (${color.x}, ${color.y}, ${color.z}) intensity=$intensity');
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
        
        // Albedo
        if (shaderData.albedo != null) {
            if (isVec3(shaderData.albedo)) {
                previewMesh.material.color.set(
                    shaderData.albedo.x,
                    shaderData.albedo.y,
                    shaderData.albedo.z
                );
            }
        }
        
        // Metallic
        if (shaderData.metallic != null && Std.is(shaderData.metallic, Float)) {
            pbrValues.metalnessValue = shaderData.metallic;
        }
        
        // Roughness
        if (shaderData.roughness != null && Std.is(shaderData.roughness, Float)) {
            pbrValues.roughnessValue = shaderData.roughness;
        }
        
        // Emissive
        if (shaderData.emissive != null && isVec3(shaderData.emissive)) {
            setEmissive(shaderData.emissive, 1.0);
        }
        
        trace('🎨 [ShaderPreview] PBR Updated');
    }
    private function isVec3(v:Dynamic):Bool {
        return v != null && Reflect.hasField(v, "x") && Reflect.hasField(v, "y") && Reflect.hasField(v, "z");
    }
    public function dispose():Void {
        if (albedoTexture != null) {
            albedoTexture.dispose();
            albedoTexture = null;
        }
        if (s3d != null) {
            s3d.dispose();
            s3d = null;
        }
        previewMesh = null;
        pbrValues = null;
        env = null;
    }
}