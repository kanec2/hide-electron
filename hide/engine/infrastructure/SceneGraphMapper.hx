package hide.engine.infrastructure;

import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.MeshRenderer;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import h3d.Quat;
import hx.injection.Service;
/**
    Отвечает за маппинг Domain-объектов в Heaps-объекты.
    ОТВЕТСТВЕННОСТЬ:
    Построение дерева h3d.Object из SceneObject
    Применение трансформаций
    Создание mesh-примитивов
    Ведение маппинга mesh → domain ID
    НЕ ЗНАЕТ:
    Про выделение, мышь, события
    ⚠️ НЕ является сервисом DI — создаётся вручную в SceneViewportController.
*/
class SceneGraphMapper {
    private var meshToDomainId:Map<Mesh, String>;
    public function new() {
        this.meshToDomainId = new Map();
    }

    /**
     * Строит дерево h3d.Object из SceneObject
     */
    public function buildObjectTree(obj:SceneObject, h3dParent:Object):Void {
        if (!obj.isActive) return;
        
        var h3dObj = new Object(h3dParent);
        h3dObj.name = obj.name;
        applyTransform(h3dObj, obj.transform);
        
        for (comp in obj.components) {
            if (Std.isOfType(comp, MeshRenderer)) {
                var mesh = createMeshPrimitive();
                if (mesh != null) {
                    meshToDomainId.set(mesh, obj.id);
                    h3dObj.addChild(mesh);
                }
            }
        }
        
        for (child in obj.children) {
            buildObjectTree(child, h3dObj);
        }
    }

    /**
     * Применяет трансформацию к h3d.Object
     */
    private function applyTransform(h3dObj:Object, t:Transform):Void {
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

    /**
     * Создаёт mesh-примитив (куб)
     */
    private function createMeshPrimitive():Null<Mesh> {
        var cube = new Cube(1, 1, 1, false);
        cube.addNormals();
        cube.addUVs();
        
        var mesh = new Mesh(cube);
        mesh.material.color.setColor(0x4a90e2);
        mesh.material.mainPass.enableLights = true;
        
        return mesh;
    }

    /**
     * Возвращает маппинг mesh → domain ID
     */
    public function getMeshToDomainId():Map<Mesh, String> {
        return meshToDomainId;
    }

    /**
     * Очищает маппинг (перед перестроением сцены)
     */
    public function clear():Void {
        meshToDomainId.clear();
    }

    /**
     * Находит domain ID по mesh
     */
    public function getDomainIdByMesh(mesh:Mesh):Null<String> {
        return meshToDomainId.get(mesh);
    }

    /**
     * Находит mesh по domain ID
     */
    public function getMeshByDomainId(id:String):Null<Mesh> {
        for (mesh => domainId in meshToDomainId) {
            if (domainId == id) return mesh;
        }
        return null;
    }
}