// hide/engine/infrastructure/HeapsRenderer.hx
package hide.engine.infrastructure;
import h3d.col.Collider;
import hide.engine.domain.services.IRenderer;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.MeshRenderer;

import hide.engine.domain.services.ISceneService;  // ← ДОБАВИТЬ

import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import h3d.prim.Cube;
import h3d.Quat;
import hx.injection.Service;

class HeapsRenderer implements IRenderer implements Service {
    private var engine:h3d.Engine;
    private var sevents:hxd.SceneEvents;  // ← НОВОЕ ПОЛЕ
    private var s3d:h3d.scene.Scene;
    private var sceneRoot:h3d.scene.Object;
    private var canvas:js.html.CanvasElement;
    private var container:Dynamic;
    private var sceneService:ISceneService;  // ← ДОБАВИТЬ
    var fpsText: h2d.Text;
    // ✅ НОВАЯ MAP: храним связь между h3d.Mesh и domain ID
    // Связь между h3d.Mesh и domain ID
    private var meshToDomainId:Map<h3d.scene.Mesh, String>;

    private var isInteractiveClicked:Bool = false;
    private var isSceneReady:Bool = false;
    private var pendingRoot:SceneObject;
    
    // === Selection outline ===
    private var bboxPrim:h3d.prim.Cube;
    private var selectionOutline:Null<h3d.scene.Mesh> = null;
    private var selectedMeshRef:Null<h3d.scene.Mesh> = null;
    private var meshOriginalColor:Map<h3d.scene.Mesh, h3d.Vector>;

    // В начале класса HeapsRenderer
    private var currentSelectedId:Null<String> = null;

    private static var isSystemInitialized:Bool = false;
    
    public function new(sceneService:ISceneService) {
        h3d.impl.RenderContext.STRICT = false;
        this.sceneService = sceneService;
        this.meshToDomainId = new Map();
        this.meshOriginalColor = new Map();

        // ✅ Создаём примитив один раз — переиспользуется для всех выделений
        this.bboxPrim = new h3d.prim.Cube(1, 1, 1, false);
        bboxPrim.addNormals();
        bboxPrim.addUVs();
    }
    
    /**
     * Обновляет визуальное выделение. Вызывается при смене selection.
     * @param id Доменный ID объекта, или null для снятия выделения
     */
    private function updateSelectionVisuals(id:Null<String>):Void {
        trace('🎯 [Selection] updateSelectionVisuals called with id=$id');
        clearSelectionVisuals(); // Сначала сбрасываем старое выделение
        if (id == null) return;
        
        // Ищем меш по domain ID
        var targetMesh:Null<h3d.scene.Mesh> = null;
        for (mesh => domainId in meshToDomainId) {
            if (domainId == id) {
                targetMesh = mesh;
                break;
            }
        }
        if (targetMesh == null) {
            trace('⚠️ [Selection] Mesh not found for id: $id');
            return;
        }
        trace('🎯 [Selection] targetMesh found: ${targetMesh != null}');
        if (targetMesh == null) return;
        
        // ✅ 1. Сохраняем ОРИГИНАЛЬНЫЙ цвет (клонируем вектор!)
        if (!meshOriginalColor.exists(targetMesh)) {
            var orig = new h3d.Vector();
            orig.set(targetMesh.material.color.x, targetMesh.material.color.y, targetMesh.material.color.z);
            meshOriginalColor.set(targetMesh, orig);
        }
        
        // Лёгкая подсветка самого меша (голубой оттенок)
        targetMesh.material.color.setColor(0x6ab0ff);
        
        // Получаем МИРОВЫЕ bounds (с учётом трансформации)
        var worldBounds = targetMesh.getBounds();

        if (worldBounds.isEmpty()) {
            trace('⚠️ [Selection] Bounds EMPTY — рамка не будет создана');
            return;
        }

        trace('🎯 [Selection] worldBounds: empty=${worldBounds.isEmpty()}, ' +
            'min=(${worldBounds.xMin},${worldBounds.yMin},${worldBounds.zMin}), ' +
            'max=(${worldBounds.xMax},${worldBounds.yMax},${worldBounds.zMax})');

        var sizeX = worldBounds.xMax - worldBounds.xMin;
        var sizeY = worldBounds.yMax - worldBounds.yMin;
        var sizeZ = worldBounds.zMax - worldBounds.zMin;
        var centerX = (worldBounds.xMax + worldBounds.xMin) / 2;
        var centerY = (worldBounds.yMax + worldBounds.yMin) / 2;
        var centerZ = (worldBounds.zMax + worldBounds.zMin) / 2;
        // Создаём mesh с готовым Cube примитивом, дочерний к сцене
        selectionOutline = new h3d.scene.Mesh(bboxPrim, sceneRoot);
        
        // Материал: оранжевый wireframe, поверх всего
        selectionOutline.material.mainPass.wireframe = true;
        selectionOutline.material.color.setColor(0xFF6600);
        selectionOutline.material.mainPass.depth(false, Always); // рисуем поверх
        selectionOutline.material.mainPass.culling = None;
        // ✅ 3. ADDITIVE BLENDING (свечение)
        selectionOutline.material.mainPass.setBlendMode(AlphaAdd);
        // Масштабируем и позиционируем под bounds объекта
        
        
        selectionOutline.x = worldBounds.xMin;
        selectionOutline.y = worldBounds.yMin;
        selectionOutline.z = worldBounds.zMin;
        selectionOutline.scaleX = sizeX * 1.05; // 5% увеличение
        selectionOutline.scaleY = sizeY * 1.05;
        selectionOutline.scaleZ = sizeZ * 1.05;
        
        selectedMeshRef = targetMesh;
        trace('📦 [Debug] Mesh pos: ${targetMesh.x},${targetMesh.y},${targetMesh.z}');
        trace('📦 [Debug] Mesh absPos: ${targetMesh.getAbsPos()}');
        trace('📦 [Debug] World bounds: min=(${worldBounds.xMin},${worldBounds.yMin},${worldBounds.zMin}) max=(${worldBounds.xMax},${worldBounds.yMax},${worldBounds.zMax})');
        trace('✨ [Selection] Outline created at (${selectionOutline.x},${selectionOutline.y},${selectionOutline.z}) ' +
            'scale=(${selectionOutline.scaleX},${selectionOutline.scaleY},${selectionOutline.scaleZ})');
    }
    /**
     * Удаляет визуальное выделение
     */
    private function clearSelectionVisuals():Void {
        if (selectionOutline != null) {
            selectionOutline.remove();
            selectionOutline = null;
        }
        
        // ✅ 2. Восстанавливаем цвета всех затронутых мешей
        for (mesh => origColor in meshOriginalColor) {
            if (mesh != null && mesh.material != null) {
                mesh.material.color.set(origColor.x, origColor.y, origColor.z);
            }
        }

        /*
        if (selectedMeshRef != null) {
            // ✅ Восстанавливаем оригинальный цвет напрямую из h3d.Vector
            if (meshOriginalColor.exists(selectedMeshRef)) {
                var orig = meshOriginalColor.get(selectedMeshRef);
                selectedMeshRef.material.color.x = orig.x;
                selectedMeshRef.material.color.y = orig.y;
                selectedMeshRef.material.color.z = orig.z;
                //selectedMeshRef.material.color.w = orig.w;
                meshOriginalColor.remove(selectedMeshRef);
            }
            selectedMeshRef = null;
        }*/
        meshOriginalColor.clear();
        currentSelectedId = null;
    }

    public function init(container:Dynamic):Void {
        // ✅ КЛЮЧЕВОЕ: отключаем строгую проверку шейдеров
        // Это предотвращает ошибки "Missing global value shadow.proj"
        // и другие шейдерные ошибки при первом рендере
        this.container = container;
    
        // ✅ ШАГ 1: Создаём canvas ПРЯМО В document.body
        // Это гарантирует, что getElementById("webgl") найдёт его
        canvas = js.Browser.document.createCanvasElement();
        canvas.id = "webgl";
        canvas.width = 800;
        canvas.height = 600;
        
        // Скрываем canvas пока движок не готов
        canvas.style.position = "absolute";
        canvas.style.top = "-9999px";
        canvas.style.left = "-9999px";
        canvas.style.visibility = "hidden";
        
        // Добавляем в body — теперь он точно в DOM
        js.Browser.document.body.appendChild(canvas);
        trace("🎨 [HeapsRenderer] Canvas created in document.body (hidden)");
        
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
        if (w < 1) w = 1000;
        if (h < 1) h = 1000;
        
        canvas.width = w;
        canvas.height = h;
        canvas.style.border = "2px solid red"; // для отладки
        canvas.style.zIndex = "9999";
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
         trace("🎨 [HeapsRenderer] Engine ready");
    
        // === ДИАГНОСТИКА ===
        trace('🔍 [Diag] hxd.Window: ${hxd.Window.getInstance()}');
        
        // ✅ УБРАНО: MaterialSetup — он не нужен для базового рендера
        // Heaps использует Forward renderer по умолчанию
        // ✅ ИСПРАВЛЕНИЕ 1: Отключаем strict mode на уровне инстанса контекста
        // Статический STRICT мог не сработать, если контекст создался раньше.
            
        s3d = new h3d.scene.Scene();
        // Это предотвращает рендеринг DefaultShadowMap pass, который требует shadow.proj
        s3d.renderer.shadows = false;
        @:privateAccess s3d.ctx.globals.fastSet(
            hxsl.Globals.allocID("shadow.proj"),
            new h3d.Matrix() // пустая матрица
        );

        sevents = new hxd.SceneEvents();
        sevents.addScene(s3d);

        sceneRoot = new h3d.scene.Object(s3d);
        
        // ✅ УБРАНО: ambientLight — в этой версии Heaps API другое
        // DirLight даст достаточно света для видимости кубов
        // В onEngineReady, после создания s3d:
        fpsText = new h2d.Text(hxd.res.DefaultFont.get());
        fpsText.textColor = 0xFFFFFF;
        fpsText.dropShadow = { dx: 1, dy: 1, color: 0, alpha: 0.5 };
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
        // ✅ ПРЯМОЙ RAYCAST ВМЕСТО INTERACTIVE
        setupMouseClickHandler();
        // ✅ ШАГ 3: Перемещаем canvas в container GoldenLayout
        moveCanvasToContainer();
        // ✅ НОВЫЙ ПОДХОД: используем Interactive для обработки кликов
        //setupInteractive();
        // ✅ КЛЮЧЕВОЕ: Запускаем непрерывный цикл рендеринга
        // Без этого Heaps не будет перерисовывать сцену
        hxd.System.setLoop(mainLoop);
        
        // ✅ Устанавливаем цвет фона, чтобы видеть, что canvas работает
        engine.backgroundColor = 0xFF2a2a2a; // тёмно-серый

        isSceneReady = true;
        trace("🎨 [HeapsRenderer] Scene created successfully");
        
        if (pendingRoot != null) {
            renderSceneInternal(pendingRoot);
            pendingRoot = null;
        }
        // ✅ ПОДПИСКА НА ВЫДЕЛЕНИЕ (из любого источника!)
        sceneService.onObjectSelected(function(id:Null<String>) {
            trace('🔗 [Heaps] ObjectSelected event: $id');
            currentSelectedId = id;
            
            if (id == null) {
                clearSelectionVisuals();
            } else {
                // Если сцена ещё не построена — ждём rebuild
                if (meshToDomainId.iterator().hasNext()) {
                    updateSelectionVisuals(id);
                } else {
                    trace('⏳ [Heaps] Scene not ready yet, selection will be restored after rebuild');
                }
            }
        });
        
        // ✅ Если при старте уже есть выделенный объект — показываем рамку
        var initialSelection = sceneService.getSelected();
        if (initialSelection != null) {
            currentSelectedId = initialSelection.id;
        }
    }

    // ✅ НОВЫЙ ПОДХОД: прямой raycast через camera.rayFromScreen()
    // ✅ ИСПРАВЛЕННЫЙ Raycast с рекурсивным обходом и отладкой
    private function setupMouseClickHandler():Void {
    // Слушаем события через hxd.Window (то, что использует SceneEvents)
        var window = hxd.Window.getInstance();
        
        window.addEventTarget(function(e:hxd.Event) {
            if (e.kind == EPush && e.button == 0) {
                // Клик произошёл — даём Interactive шанс обработать
                isInteractiveClicked = false;
                
                // Проверяем в следующем кадре, был ли клик обработан
                haxe.Timer.delay(function() {
                    if (!isInteractiveClicked) {
                        trace("❌ Click on empty space");
                        sceneService.deselect();
                    }
                }, 0);
            }
        });
    }

    private function moveCanvasToContainer():Void {
        if (canvas == null) return;
        
        // Перемещаем canvas из body в container GoldenLayout
        if (container != null && container.appendChild != null) {
            container.appendChild(canvas);
            trace("🎨 [HeapsRenderer] Canvas moved to container");
        }
        
        // Применяем стили для правильного отображения внутри GoldenLayout
        canvas.style.position = "absolute";
        canvas.style.top = "0";
        canvas.style.left = "0";
        canvas.style.width = "100%";
        canvas.style.height = "100%";
        canvas.style.zIndex = "10";
        canvas.style.pointerEvents = "auto";
        canvas.style.visibility = "visible";
        
        // Обновляем размеры canvas под контейнер
        updateCanvasSize();
    }
    private function updateCanvasSize():Void {
        if (canvas == null || container == null) return;
        
        var rect = container.getBoundingClientRect();
        var w:Int = Std.int(rect.width);
        var h:Int = Std.int(rect.height);
        
        if (w < 1) w = 1;
        if (h < 1) h = 1;
        
        canvas.width = w;
        canvas.height = h;
        
        trace("🎨 [HeapsRenderer] Canvas size: " + w + "x" + h);
        
        if (s3d != null) {
            s3d.camera.update();
        }
    }

    private var fpsAccumulator:Float = 0;
    private var frameCount:Int = 0;
    private var fpsTimer:Float = 0;
    // ✅ НОВЫЙ МЕТОД: главный цикл рендеринга
    private function mainLoop():Void {
        hxd.Timer.update();
        if (sevents != null) sevents.checkEvents();
        if (engine != null && s3d != null) engine.render(s3d);
        
        fpsTimer += hxd.Timer.dt;
        if (fpsTimer >= 0.5) {  // обновляем 2 раза в секунду
            var fps = 1.0 / hxd.Timer.dt;
            fpsText.text = 'FPS: ${Std.int(fps)}';
            fpsTimer = 0;
        }
        /*
        if (fpsAccumulator >= 1.0) {
            var fps = frameCount / fpsAccumulator;
            var frameMs = hxd.Timer.elapsedTime * 1000;  // ← реальное время кадра
            trace('📊 FPS: ${Std.int(fps)} | frame: ${Std.int(frameMs)}ms');
            
            frameCount = 0;
            fpsAccumulator = 0;
        }*/
    }
    public function renderScene(root:SceneObject):Void {
        if (!isSceneReady) {
            pendingRoot = root;
            return;
        }
        renderSceneInternal(root);
    }
    
    private function renderSceneInternal(root:SceneObject):Void {
        // Сохраняем ID выделенного объекта до rebuild
        var savedSelectionId = currentSelectedId;

        // ✅ СНАЧАЛА очищаем выделение (восстанавливаем цвета)
        clearSelectionVisuals();

        var toRemove:Array<h3d.scene.Object> = [];
        for (child in sceneRoot) {
            if (child != sceneRoot) toRemove.push(child);
        }
        for (child in toRemove) {
            child.remove();
        }
        // ✅ ОЧИЩАЕМ MAP перед перестроением
        meshToDomainId.clear();
        meshOriginalColor.clear();

        buildObjectTree(root, sceneRoot);
        // ✅ Создаём Interactive для всех мешей после построения дерева

        // ✅ Восстанавливаем выделение, если оно было
        if (savedSelectionId != null) {
            trace('🔄 [Heaps] Restoring selection after rebuild: $savedSelectionId');
            // Используем haxe.Timer.delay, чтобы дать сцене синхронизироваться
            haxe.Timer.delay(function() {
                updateSelectionVisuals(savedSelectionId);
            }, 0);
        }

    }
    
    public function onResize(width:Int, height:Int):Void {
        updateCanvasSize();
    }
    
    public function dispose():Void {
        
        clearSelectionVisuals();

        if (s3d != null) {
            s3d.dispose();
            s3d = null;
        }
        
        if (canvas != null && canvas.parentElement != null) {
            canvas.parentElement.removeChild(canvas);
            canvas = null;
        }
        
        engine = null;
        meshToDomainId.clear();
        meshOriginalColor.clear();
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
                    // ✅ Синхронизируем позицию перед получением bounds
                    @:privateAccess mesh.syncPos();
                    // ✅ Получаем локальные bounds
                    var localBounds = mesh.getBounds(null, mesh);
                    
                    if (!localBounds.isEmpty()) {
                        // Создаём Interactive — он автоматически зарегистрируется
                        // в scene.events через onAdd()
                        var interaction = new h3d.scene.Interactive(localBounds, mesh);
                        
                        interaction.onClick = function(e:hxd.Event) {
                            trace('✅ [Interactive] Clicked: ${obj.name}');
                            isInteractiveClicked = true;
                            sceneService.select(obj.id);
                            e.cancel = true;
                        }
                        
                        interaction.onOver = function(e:hxd.Event) {
                            // НЕ меняем цвет, если объект выделен
                            if (selectedMeshRef != mesh) {
                                mesh.material.color.setColor(0x6ab0ff);
                            }
                        }
                        
                        interaction.onOut = function(e:hxd.Event) {
                            // Восстанавливаем цвет ТОЛЬКО если объект НЕ выделен
                            if (selectedMeshRef != mesh) {
                                // Восстанавливаем оригинальный цвет из map
                                if (meshOriginalColor.exists(mesh)) {
                                    var orig = meshOriginalColor.get(mesh);
                                    mesh.material.color.x = orig.x;
                                    mesh.material.color.y = orig.y;
                                    mesh.material.color.z = orig.z;
                                } else {
                                    mesh.material.color.setColor(0x4a90e2); // fallback
                                }
                            }
                        }
                    } else {
                        trace('⚠️ [Interactive] Bounds EMPTY for ${obj.name}');
                    }
                    
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
