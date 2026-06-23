// hide/engine/infrastructure/SceneViewportController.hx
package hide.engine.infrastructure;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineEventBus;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.MeshRenderer;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Cube;
import h3d.Quat;
import hx.injection.Service;

/**
 * Контроллер viewport'а Scene Editor.
 * Отвечает за:
 * - Создание сцены для Scene Editor
 * - Построение дерева объектов (buildObjectTree)
 * - Визуальное выделение (selection outline)
 * - Обработку кликов мыши (picking)
 */
class SceneViewportController implements Service {
    private var sceneService:ISceneService;
    private var viewportService:ViewportService;
    private var engineEventBus:IEngineEventBus;
    
    private var viewport:Null<Viewport>;
    private var scene:h3d.scene.Scene;
    private var sceneRoot:h3d.scene.Object;
    
    // Selection & Mesh mapping
    private var meshToDomainId:Map<h3d.scene.Mesh, String>;
    private var bboxPrim:h3d.prim.Cube;
    private var selectionOutline:Null<h3d.scene.Mesh> = null;
    private var selectedMeshRef:Null<h3d.scene.Mesh> = null;
    private var meshOriginalColor:Map<h3d.scene.Mesh, h3d.Vector>;
    private var currentSelectedId:Null<String> = null;
    private var isInteractiveClicked:Bool = false;
    
    private var container:Dynamic;
    private var isAttached:Bool = false;

    public function new(
        sceneService:ISceneService,
        viewportService:ViewportService,
        engineEventBus:IEngineEventBus
    ) {
        this.sceneService = sceneService;
        this.viewportService = viewportService;
        this.engineEventBus = engineEventBus;
        
        this.meshToDomainId = new Map();
        this.meshOriginalColor = new Map();
        this.bboxPrim = new h3d.prim.Cube(1, 1, 1, false);
        bboxPrim.addNormals();
        bboxPrim.addUVs();
        
        // Подписки на события движка
        engineEventBus.onObjectSelected(onObjectSelected);
        engineEventBus.onSceneChanged(onSceneChanged);
    }
    
    /**
     * Вызывается из SceneViewFactory для привязки к DOM-контейнеру.
     */
    public function attachTo(container:Dynamic):Void {
        this.container = container;
        
        // ✅ ПРОВЕРКА: engine должен быть инициализирован
        var engine = h3d.Engine.getCurrent();
        if (engine == null || @:privateAccess engine.driver == null) {
            trace("⏳ [SceneViewport] Engine not ready, retrying in 50ms...");
            haxe.Timer.delay(function() attachTo(container), 50);
            return;
        }
        
        if (isAttached) {
            trace("⚠️ [SceneViewport] Already attached");
            return;
        }
        isAttached = true;
        
        scene = new h3d.scene.Scene();
        scene.renderer.shadows = false;
        @:privateAccess scene.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix()
        );
        
        sceneRoot = new h3d.scene.Object(scene);
        
        var camera = scene.camera;
        camera.pos.set(8, 8, 8);
        camera.target.set(0, 0, 0);
        camera.fovY = 45;
        camera.zNear = 0.1;
        camera.zFar = 1000;
        camera.update();
        
        var light = new DirLight(new h3d.Vector(-0.5, -0.5, -1), scene);
        
        // Регистрируем viewport
        viewport = viewportService.register("scene-editor", scene, 800, 600);
        container.appendChild(viewport.canvas);
        
        setupMouseClickHandler();
        
        // Первичный рендер
        renderSceneInternal(sceneService.getRoot());
        trace('🔍 [Debug] Scene root children count: ${@:privateAccess sceneRoot.children.length}');
        for (child in sceneRoot) {
            trace('   └─ ${child.name} (${Type.getClassName(Type.getClass(child))})');
            // Временная проверка: красим все объекты в ярко-розовый
            for (c in child) {
                if (Std.isOfType(c, h3d.scene.Mesh)) {
                    var mesh:h3d.scene.Mesh = cast c;
                    mesh.material.color.setColor(0xFF00FF); // Ярко-розовый
                    trace("      🎨 Mesh colored PINK");
                }
            }
        }
        trace(" [SceneViewportController] Attached to container");
    }
    
    private function onSceneChanged():Void {
        renderSceneInternal(sceneService.getRoot());
    }
    
    private function onObjectSelected(id:Null<String>):Void {
        currentSelectedId = id;
        if (id == null) {
            clearSelectionVisuals();
        } else {
            if (meshToDomainId.iterator().hasNext()) {
                updateSelectionVisuals(id);
            }
        }
    }
    
    // === ЛОГИКА ПОСТРОЕНИЯ ДЕРЕВА ===
    
    private function renderSceneInternal(root:SceneObject):Void {
        var savedSelectionId = currentSelectedId;
        clearSelectionVisuals();
        
        var toRemove:Array<h3d.scene.Object> = [];
        for (child in sceneRoot) {
            if (child != sceneRoot) toRemove.push(child);
        }
        for (child in toRemove) child.remove();
        
        meshToDomainId.clear();
        meshOriginalColor.clear();
        
        buildObjectTree(root, sceneRoot);
        
        if (savedSelectionId != null) {
            haxe.Timer.delay(function() updateSelectionVisuals(savedSelectionId), 0);
        }
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
                    meshToDomainId.set(mesh, obj.id);
                    h3dObj.addChild(mesh);
                    @:privateAccess mesh.syncPos();
                    
                    var localBounds = mesh.getBounds(null, mesh);
                    if (!localBounds.isEmpty()) {
                        var interaction = new h3d.scene.Interactive(localBounds, mesh);
                        interaction.onClick = function(e:hxd.Event) {
                            isInteractiveClicked = true;
                            sceneService.select(obj.id);
                            e.cancel = true;
                        }
                        interaction.onOver = function(e:hxd.Event) {
                            if (selectedMeshRef != mesh) mesh.material.color.setColor(0x6ab0ff);
                        }
                        interaction.onOut = function(e:hxd.Event) {
                            if (selectedMeshRef != mesh) {
                                if (meshOriginalColor.exists(mesh)) {
                                    var orig = meshOriginalColor.get(mesh);
                                    mesh.material.color.set(orig.x, orig.y, orig.z);
                                } else {
                                    mesh.material.color.setColor(0x4a90e2);
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for (child in obj.children) buildObjectTree(child, h3dObj);
    }
    
    private function applyTransform(h3dObj:h3d.scene.Object, t:Transform):Void {
        h3dObj.x = t.x; h3dObj.y = t.y; h3dObj.z = t.z;
        var q = new Quat();
        q.initRotation(t.rotX * Math.PI / 180, t.rotY * Math.PI / 180, t.rotZ * Math.PI / 180);
        h3dObj.setRotationQuat(q);
        h3dObj.scaleX = t.scaleX; h3dObj.scaleY = t.scaleY; h3dObj.scaleZ = t.scaleZ;
    }
    
    private function createMeshPrimitive():Null<Mesh> {
        var cube = new Cube(1, 1, 1, false);
        cube.addNormals(); cube.addUVs();
        var mesh = new Mesh(cube);
        mesh.material.color.setColor(0x4a90e2);
        mesh.material.mainPass.enableLights = true;
        return mesh;
    }
    
    // === ЛОГИКА ВЫДЕЛЕНИЯ ===
    
    private function updateSelectionVisuals(id:Null<String>):Void {
        clearSelectionVisuals();
        if (id == null) return;
        
        var targetMesh:Null<h3d.scene.Mesh> = null;
        for (mesh => domainId in meshToDomainId) {
            if (domainId == id) { targetMesh = mesh; break; }
        }
        if (targetMesh == null) return;
        
        if (!meshOriginalColor.exists(targetMesh)) {
            var orig = new h3d.Vector();
            orig.set(targetMesh.material.color.x, targetMesh.material.color.y, targetMesh.material.color.z);
            meshOriginalColor.set(targetMesh, orig);
        }
        
        targetMesh.material.color.setColor(0x6ab0ff);
        var worldBounds = targetMesh.getBounds();
        if (worldBounds.isEmpty()) return;
        
        var sizeX = worldBounds.xMax - worldBounds.xMin;
        var sizeY = worldBounds.yMax - worldBounds.yMin;
        var sizeZ = worldBounds.zMax - worldBounds.zMin;
        
        selectionOutline = new h3d.scene.Mesh(bboxPrim, sceneRoot);
        selectionOutline.material.mainPass.wireframe = true;
        selectionOutline.material.color.setColor(0xFF6600);
        selectionOutline.material.mainPass.depth(false, Always);
        selectionOutline.material.mainPass.culling = None;
        selectionOutline.material.mainPass.setBlendMode(AlphaAdd);
        
        selectionOutline.x = worldBounds.xMin;
        selectionOutline.y = worldBounds.yMin;
        selectionOutline.z = worldBounds.zMin;
        selectionOutline.scaleX = sizeX * 1.05;
        selectionOutline.scaleY = sizeY * 1.05;
        selectionOutline.scaleZ = sizeZ * 1.05;
        
        selectedMeshRef = targetMesh;
    }
    
    private function clearSelectionVisuals():Void {
        if (selectionOutline != null) {
            selectionOutline.remove();
            selectionOutline = null;
        }
        for (mesh => origColor in meshOriginalColor) {
            if (mesh != null && mesh.material != null) {
                mesh.material.color.set(origColor.x, origColor.y, origColor.z);
            }
        }
        meshOriginalColor.clear();
        currentSelectedId = null;
    }
    
    // === МЫШЬ ===
    
    private function setupMouseClickHandler():Void {
        var window = hxd.Window.getInstance();
        window.addEventTarget(function(e:hxd.Event) {
            if (e.kind == EPush && e.button == 0) {
                isInteractiveClicked = false;
                haxe.Timer.delay(function() {
                    if (!isInteractiveClicked) sceneService.deselect();
                }, 0);
            }
        });
    }
    
    public function dispose():Void {
        if (viewport != null) {
            viewportService.removeViewport(viewport.id);
            viewport = null;
        }
    }
}