package hide.engine.infrastructure;

import h3d.scene.Mesh;
import h3d.scene.Object;
import h3d.prim.Cube;
import hx.injection.Service;
/**
    Отвечает за визуальное выделение объектов в сцене.
    ОТВЕТСТВЕННОСТЬ:
    Создание и удаление wireframe-рамок
    Подсветка выделенных mesh
    Сохранение и восстановление оригинальных цветов
    НЕ ЗНАЕТ:
    Про Domain-объекты, мышь, события движка
    ⚠️ НЕ является сервисом DI, потому что зависит от sceneRoot,
    который создаётся в runtime (в SceneViewportController).
*/
class SelectionSystem {
    private var bboxPrim:Cube;
    private var selectionOutline:Null<Mesh> = null;
    private var selectedMeshRef:Null<Mesh> = null;
    private var meshOriginalColor:Map<Mesh, h3d.Vector>;
    private var currentSelectedId:Null<String> = null;
    private var sceneRoot:Object;
    
    public function new(sceneRoot:Object) {
        this.sceneRoot = sceneRoot;
        this.meshOriginalColor = new Map();
        
        // Создаём примитив один раз — переиспользуется для всех выделений
        this.bboxPrim = new Cube(1, 1, 1, false);
            bboxPrim.addNormals();
            bboxPrim.addUVs();
    }

    /**
     * Обновляет визуальное выделение
     */
    public function updateSelectionVisuals(id:Null<String>, getMeshById:String->Null<Mesh>):Void {
        trace('🎯 [Selection] updateSelectionVisuals called with id=$id');
        clearSelectionVisuals();
        
        if (id == null) return;
        
        var targetMesh = getMeshById(id);
        if (targetMesh == null) {
            trace('⚠️ [Selection] Mesh not found for id: $id');
            return;
        }
        
        trace('🎯 [Selection] targetMesh found: ${targetMesh != null}');
        
        // Сохраняем оригинальный цвет
        if (!meshOriginalColor.exists(targetMesh)) {
            var orig = new h3d.Vector();
            orig.set(
                targetMesh.material.color.x,
                targetMesh.material.color.y,
                targetMesh.material.color.z
            );
            meshOriginalColor.set(targetMesh, orig);
        }
        
        // Подсвечиваем mesh
        targetMesh.material.color.setColor(0x6ab0ff);
        
        // Получаем мировые bounds
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
        
        // Создаём wireframe-рамку
        selectionOutline = new Mesh(bboxPrim, sceneRoot);
        selectionOutline.material.mainPass.wireframe = true;
        selectionOutline.material.color.setColor(0xFF6600);
        selectionOutline.material.mainPass.depth(false, Always);
        selectionOutline.material.mainPass.culling = None;
        selectionOutline.material.mainPass.setBlendMode(AlphaAdd);
        
        // Позиционируем и масштабируем под bounds
        selectionOutline.x = worldBounds.xMin;
        selectionOutline.y = worldBounds.yMin;
        selectionOutline.z = worldBounds.zMin;
        selectionOutline.scaleX = sizeX * 1.05;
        selectionOutline.scaleY = sizeY * 1.05;
        selectionOutline.scaleZ = sizeZ * 1.05;
        
        selectedMeshRef = targetMesh;
        currentSelectedId = id;
        
        trace('✨ [Selection] Outline created at (${selectionOutline.x},${selectionOutline.y},${selectionOutline.z}) ' +
            'scale=(${selectionOutline.scaleX},${selectionOutline.scaleY},${selectionOutline.scaleZ})');
    }

    /**
     * Удаляет визуальное выделение
     */
    public function clearSelectionVisuals():Void {
        if (selectionOutline != null) {
            selectionOutline.remove();
            selectionOutline = null;
        }
        
        // Восстанавливаем цвета всех затронутых mesh
        for (mesh => origColor in meshOriginalColor) {
            if (mesh != null && mesh.material != null) {
                mesh.material.color.set(origColor.x, origColor.y, origColor.z);
            }
        }
        
        meshOriginalColor.clear();
        currentSelectedId = null;
    }

    /**
     * Возвращает текущий выделенный ID
     */
    public function getCurrentSelectedId():Null<String> {
        return currentSelectedId;
    }

    /**
     * Устанавливает текущий выделенный ID (без визуализации)
     */
    public function setCurrentSelectedId(id:Null<String>):Void {
        currentSelectedId = id;
    }

    /**
     * Проверяет, является ли mesh выделенным
     */
    public function isMeshSelected(mesh:Mesh):Bool {
        return selectedMeshRef == mesh;
    }

    /**
     * Подсвечивает mesh при наведении (если не выделен)
     */
    public function highlightMeshOnHover(mesh:Mesh):Void {
        if (!isMeshSelected(mesh)) {
            mesh.material.color.setColor(0x6ab0ff);
        }
    }

    /**
     * Восстанавливает цвет mesh при уходе курсора (если не выделен)
     */
    public function restoreMeshColorOnHoverOut(mesh:Mesh):Void {
        if (!isMeshSelected(mesh)) {
            if (meshOriginalColor.exists(mesh)) {
                var orig = meshOriginalColor.get(mesh);
                mesh.material.color.set(orig.x, orig.y, orig.z);
            } else {
                mesh.material.color.setColor(0x4a90e2); // fallback
            }
        }
    }
}