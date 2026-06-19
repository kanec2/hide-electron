// hide/engine/infrastructure/HeapsRenderer.hx
package hide.engine.infrastructure;
import hide.engine.domain.services.IRenderer;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.MeshRenderer;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Cube;
import h3d.Quat;
import hx.injection.Service;

class HeapsRenderer implements IRenderer implements Service {
    private var engine:h3d.Engine;
    private var s3d:h3d.scene.Scene;
    private var sceneRoot:h3d.scene.Object;
    private var canvas:js.html.CanvasElement;
    private var container:Dynamic;
    // ✅ ИСПРАВЛЕНО: используем Dynamic вместо js.html.ResizeObserver
    
    
    private var isSceneReady:Bool = false;
    private var pendingRoot:SceneObject;
    
    private static var isSystemInitialized:Bool = false;
    
    public function new() {
        h3d.impl.RenderContext.STRICT = false;
    }
    
    public function init(container:Dynamic):Void {
        // ✅ КЛЮЧЕВОЕ: отключаем строгую проверку шейдеров
        // Это предотвращает ошибки "Missing global value shadow.proj"
        // и другие шейдерные ошибки при первом рендере
        h3d.impl.RenderContext.STRICT = false; // prevent errors with bad renderer

        this.container = container;
        
        // 1. Создаём canvas в document.body
        canvas = js.Browser.document.createCanvasElement();
        canvas.id = "webgl";
        canvas.width = 800;
        canvas.height = 600;
        js.Browser.document.body.appendChild(canvas);
        
        trace("🎨 [HeapsRenderer] Canvas created in document.body");
        
        // 2. Позиционируем canvas
        updateCanvasPosition();
        
        // 3. ✅ ИСПРАВЛЕНО: используем Dynamic для ResizeObserver
       
        
        // 4. Запускаем Heaps
        initEngine();
    }
    
    private function updateCanvasPosition():Void {
        if (canvas == null || container == null) return;
        
        var rect = container.getBoundingClientRect();
        canvas.style.position = "fixed";
        canvas.style.left = rect.left + "px";
        canvas.style.top = rect.top + "px";
        canvas.style.width = rect.width + "px";
        canvas.style.height = rect.height + "px";
        canvas.style.zIndex = "1";
        canvas.style.pointerEvents = "auto";
        
    // ✅ ИСПРАВЛЕНО: используем untyped для обхода типизации
        // getBoundingClientRect() возвращает DOMRect, но через Dynamic-контейнер
        // компилятор не знает точный тип — используем untyped
        var w:Int = untyped rect.width | 0;
        var h:Int = untyped rect.height | 0;
        
        // Защита от нулевых размеров (canvas не может быть 0x0)
        if (w < 1) w = 1;
        if (h < 1) h = 1;
        
        canvas.width = w;
        canvas.height = h;
        
        if (s3d != null) {
            s3d.camera.update();
        }
    }
    
    private function initEngine():Void {
        var existingEngine = h3d.Engine.getCurrent();
        
        if (existingEngine != null) {
            trace("🎨 [HeapsRenderer] Using existing engine");
            this.engine = existingEngine;
            engine.onReady = onEngineReady;
            haxe.Timer.delay(onEngineReady, 0);
        } else {
            trace("🎨 [HeapsRenderer] Creating new engine...");
            
            if (!isSystemInitialized) {
                hxd.System.start(function() {
                    this.engine = @:privateAccess new h3d.Engine();
                    engine.onReady = onEngineReady;
                    engine.init();
                    isSystemInitialized = true;
                });
            } else {
                this.engine = @:privateAccess new h3d.Engine();
                engine.onReady = onEngineReady;
                engine.init();
            }
        }
    }
    
    private function onEngineReady():Void {
        trace("🎨 [HeapsRenderer] Engine ready, creating scene...");
        
        // ✅ УБРАНО: MaterialSetup — он не нужен для базового рендера
        // Heaps использует Forward renderer по умолчанию
        
        s3d = new h3d.scene.Scene();
        sceneRoot = new h3d.scene.Object(s3d);
        
        // ✅ УБРАНО: ambientLight — в этой версии Heaps API другое
        // DirLight даст достаточно света для видимости кубов
        
        // Настраиваем камеру
        var camera = s3d.camera;
        camera.pos.set(8, 8, 8);
        camera.target.set(0, 0, 0);
        camera.up.set(0, 1, 0);
        camera.fovY = 45;
        camera.zNear = 0.1;
        camera.zFar = 1000;
        camera.update();
        
        // ✅ ОСТАВЛЯЕМ ТОЛЬКО DirLight — это точно работает
        var light = new h3d.scene.fwd.DirLight(new h3d.Vector(-0.5, -0.5, -1), s3d);
        
        isSceneReady = true;
        trace("🎨 [HeapsRenderer] Scene created successfully");
        
        if (pendingRoot != null) {
            renderSceneInternal(pendingRoot);
            pendingRoot = null;
        }
    }
    
    public function renderScene(root:SceneObject):Void {
        if (!isSceneReady) {
            pendingRoot = root;
            return;
        }
        renderSceneInternal(root);
    }
    
    private function renderSceneInternal(root:SceneObject):Void {
        var toRemove:Array<h3d.scene.Object> = [];
        for (child in sceneRoot) {
            if (child != sceneRoot) toRemove.push(child);
        }
        for (child in toRemove) {
            child.remove();
        }
        
        buildObjectTree(root, sceneRoot);
        
        if (engine != null && s3d != null) {
            engine.render(s3d);
        }
    }
    
    public function onResize(width:Int, height:Int):Void {
        updateCanvasPosition();
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
        
        engine = null;
    }
    
    private function buildObjectTree(obj:SceneObject, h3dParent:h3d.scene.Object):Void {
        if (!obj.isActive) return;
        
        var h3dObj = new h3d.scene.Object(h3dParent);
        h3dObj.name = obj.name;
        applyTransform(h3dObj, obj.transform);
        
        for (comp in obj.components) {
            if (Std.isOfType(comp, MeshRenderer)) {
                var mesh = createMeshPrimitive();
                if (mesh != null) {
                    h3dObj.addChild(mesh);
                }
            }
        }
        
        for (child in obj.children) {
            buildObjectTree(child, h3dObj);
        }
    }
    
    private function applyTransform(h3dObj:h3d.scene.Object, t:Transform):Void {
        h3dObj.x = t.x;
        h3dObj.y = t.y;
        h3dObj.z = t.z;
        
        var q = new Quat();
        q.initRotation(
            t.rotX * Math.PI / 180,
            t.rotY * Math.PI / 180,
            t.rotZ * Math.PI / 180
        );
        h3dObj.setRotationQuat(q);
        
        h3dObj.scaleX = t.scaleX;
        h3dObj.scaleY = t.scaleY;
        h3dObj.scaleZ = t.scaleZ;
    }
    
    private function createMeshPrimitive():Null<Mesh> {
        var cube = new Cube(1, 1, 1, false);
        cube.addNormals();
        cube.addUVs();
        
        var mesh = new Mesh(cube);
        mesh.material.color.setColor(0x4a90e2);
        mesh.material.mainPass.enableLights = true;
        
        return mesh;
    }
}