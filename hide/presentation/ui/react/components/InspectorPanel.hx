package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.shared.events.ObjectSelected;
import hide.shared.events.ObjectChanged;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hide.engine.domain.entities.MeshRenderer;
import hide.engine.domain.entities.Rigidbody;
import hide.presentation.ui.react.components.ComponentIcon; // Не забудьте импортировать иконку

typedef InspectorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef InspectorState = {
    var selectedObject: Null<SceneObject>;
    var collapsedComponents: Map<String, Bool>;
}

class InspectorPanel extends BaseReactComponent<InspectorProps, InspectorState> {
    
    public function new() {
        super();
        state = { 
            selectedObject: null,
            collapsedComponents: new Map() 
        };
    }

    override function componentDidMount(): Void {
        var eventBus = UseService.eventBus();
        var scene = UseService.sceneService();

        // 1. Синхронная инициализация при монтировании
        var initialObj = scene.getSelected();
        setState({ 
            selectedObject: initialObj,
            collapsedComponents: new Map() 
        });

        // 2. Подписка на выбор объекта
        subscribe(eventBus, ObjectSelected, function(e:ObjectSelected) {
            trace('🔍 [Inspector] Received ObjectSelected: ${e.objectId}');
            
            var obj = e.objectId != null ? scene.getObject(e.objectId) : null;
            
            // Оптимизация: не обновляем, если объект тот же самый (по ссылке)
            if (state.selectedObject == obj) return;
            
            // ✅ СОХРАНЯЕМ collapsedComponents
            setState({ 
                selectedObject: obj,
                collapsedComponents: state.collapsedComponents 
            });
        });

        // 3. Подписка на изменения свойств
        subscribe(eventBus, ObjectChanged, function(e:ObjectChanged) {
            if (state.selectedObject != null && state.selectedObject.id == e.objectId) {
                var fresh = scene.getObject(e.objectId);
                // ✅ СОХРАНЯЕМ collapsedComponents
                setState({ 
                    selectedObject: fresh,
                    collapsedComponents: state.collapsedComponents 
                });
            }
        });
    }

    // ===== Сворачивание =====
    private function toggleCollapse(componentKey: String): Void {
        var isCollapsed = state.collapsedComponents.get(componentKey);
        if (isCollapsed == null) isCollapsed = false;
        
        var newMap = state.collapsedComponents.copy();
        newMap.set(componentKey, !isCollapsed);
        
        setState({ 
            selectedObject: state.selectedObject,
            collapsedComponents: newMap 
        });
    }

    // ===== Рендеринг =====
    override function render(): ReactElement {
        var obj = state.selectedObject;

        var header: ReactElement = if (obj != null) {
            jsx('
                <div className="inspector-header">
                    <div className="inspector-header-content">
                        <input type="checkbox" defaultChecked={obj.isActive} onChange={function(_) toggleActive(obj.id)} />
                        <b>{obj.name}</b>
                        <span className="inspector-id">id: {obj.id}</span>
                    </div>
                </div>
            ');
        } else {
            jsx('<div className="inspector-empty">No object selected</div>');
        };

        var componentsList: ReactElement = if (obj != null) {
            jsx('
                <div className="inspector-components">
                    {renderTransform(obj)}
                    {[for (c in obj.components) renderComponent(obj.id, c)]}
                    <div className="inspector-add-btn-wrapper">
                        <button className="btn-add-component">Add Component</button>
                    </div>
                </div>
            ');
        } else {
            jsx('<div></div>');
        };

        return jsx('
            <div className="inspector-panel">
                {header}
                {componentsList}
            </div>
        ');
    }

    private function renderTransform(obj: SceneObject): ReactElement {
        var t = obj.transform;
        var compId = "transform"; // Уникальный ID для Transform
        var isCollapsed = state.collapsedComponents.get(compId) == true;
        // 1. Сначала выполняем все вызовы функций и сохраняем результаты в переменные
        var posInputs = renderVector3("Position", t.x, t.y, t.z, 
            function(x,y,z) setTransform(obj.id, x,y,z, t.rotX,t.rotY,t.rotZ, t.scaleX,t.scaleY,t.scaleZ));
        
        var rotInputs = renderVector3("Rotation", t.rotX, t.rotY, t.rotZ, 
            function(x,y,z) setTransform(obj.id, t.x,t.y,t.z, x,y,z, t.scaleX,t.scaleY,t.scaleZ));
            
        var scaleInputs = renderVector3("Scale", t.scaleX, t.scaleY, t.scaleZ, 
            function(x,y,z) setTransform(obj.id, t.x,t.y,t.z, t.rotX,t.rotY,t.rotZ, x,y,z));

        var componentContent = !isCollapsed ? jsx('
                    <div className="component-body">
                        {posInputs}
                        {rotInputs}
                        {scaleInputs}
                    </div>
                ') : null;
        // 2. Используем эти переменные внутри jsx()
        return jsx('
            <div className="component-block">
                <div 
                    className="component-title" 
                    onClick={function(_) toggleCollapse(compId)}
                    style={{cursor: "pointer"}}
                >
                    <span style={{width: "16px", textAlign: "center", fontSize: "10px", marginRight: "4px"}}>
                        {isCollapsed ? "▶" : "▼"}
                    </span>
                    <ComponentIcon className="hide.engine.domain.entities.Transform" />
                
                    Transform
                </div>
                {componentContent}
            </div>
        ');
    }

    // ===== Компоненты (с иконками и уникальными ключами) =====
    private function renderComponent(objId: String, comp: hide.engine.domain.entities.SceneComponent): ReactElement {
        var className = Type.getClassName(Type.getClass(comp));
        // ✅ УНИКАЛЬНЫЙ КЛЮЧ: Тип + ID
        var uniqueKey = className + "_" + comp.id; 
        
        var isCollapsed = state.collapsedComponents.get(uniqueKey) == true;

        var titleContent = switch (className) {
            case "hide.engine.domain.entities.MeshRenderer": "Mesh Renderer";
            case "hide.engine.domain.entities.Rigidbody": "Rigidbody";
            default: comp.name;
        };

        var bodyContent: ReactElement = switch (className) {
            case "hide.engine.domain.entities.MeshRenderer":
                var m: MeshRenderer = cast comp;
                jsx('
                    <div className="component-body">
                        {renderStringField("Mesh", m.meshPath, function(v) setMesh(objId, v, m.materialPath))}
                        {renderStringField("Material", m.materialPath, function(v) setMesh(objId, m.meshPath, v))}
                    </div>
                ');
            case "hide.engine.domain.entities.Rigidbody":
                var r: Rigidbody = cast comp;
                jsx('
                    <div className="component-body">
                        {renderNumberField("Mass", r.mass, function(v) setRigidbody(objId, v, r.useGravity))}
                        <div className="field-row checkbox-row">
                            <label>Gravity</label>
                            <input type="checkbox" defaultChecked={r.useGravity}
                                onChange={function(_) setRigidbody(objId, r.mass, !r.useGravity)} />
                        </div>
                    </div>
                ');
            default:
                jsx('<div className="component-body">Unknown component: {comp.name}</div>');
        };

        return jsx('
            <div key={uniqueKey} className="component-block">
                <div 
                    className="component-title" 
                    onClick={function(_) toggleCollapse(uniqueKey)}
                    style={{cursor: "pointer", display: "flex", alignItems: "center"}}
                >
                    <span style={{width: "16px", textAlign: "center", fontSize: "10px", marginRight: "4px"}}>
                        {isCollapsed ? "▶" : "▼"}
                    </span>
                    <ComponentIcon className={className} />
                    {titleContent}
                </div>
                
                {!isCollapsed ? bodyContent : null}
            </div>
        ');
    }

    // ===== Поля ввода (адаптивные) =====
    private function renderVector3(label: String, x: Float, y: Float, z: Float, onChange: Float->Float->Float->Void): ReactElement {
        return jsx('
            <div className="field-row vector-row">
                <label className="field-label">{label}</label>
                <div className="vector-inputs">
                    <input defaultValue={x} className="num-input"
                        onBlur={function(e) onChange(safeParse(e.target.value,0), y, z)} />
                    <input defaultValue={y} className="num-input"
                        onBlur={function(e) onChange(x, safeParse(e.target.value,0), z)} />
                    <input defaultValue={z} className="num-input"
                        onBlur={function(e) onChange(x, y, safeParse(e.target.value,0))} />
                </div>
            </div>
        ');
    }

    private function renderStringField(label: String, value: String, onChange: String->Void): ReactElement {
        return jsx('
            <div className="field-row">
                <label className="field-label">{label}</label>
                <input defaultValue={value} className="text-input"
                    onBlur={function(e) onChange(e.target.value)} />
            </div>
        ');
    }

    private function renderNumberField(label: String, value: Float, onChange: Float->Void): ReactElement {
        return jsx('
            <div className="field-row">
                <label className="field-label">{label}</label>
                <input defaultValue={value} className="num-input full-width"
                    onBlur={function(e) onChange(safeParse(e.target.value,0))} />
            </div>
        ');
    }

    // ===== Логика =====
    private function setTransform(objId: String, px:Float, py:Float, pz:Float, rx:Float, ry:Float, rz:Float, sx:Float, sy:Float, sz:Float): Void {
        UseService.sceneService().setTransform(objId, new Transform(px, py, pz, rx, ry, rz, sx, sy, sz));
    }

    private function setMesh(objId: String, meshPath: String, matPath: String): Void {
        UseService.sceneService().setMeshRenderer(objId, meshPath, matPath);
    }

    private function setRigidbody(objId: String, mass: Float, gravity: Bool): Void {
        UseService.sceneService().setRigidbody(objId, mass, gravity);
    }

    private function toggleActive(objId: String): Void {
        var obj = UseService.sceneService().getObject(objId);
        if (obj == null) return;
        UseService.sceneService().setActive(objId, !obj.isActive);
    }

    private function safeParse(v:String, fallback:Float):Float {
        var f = Std.parseFloat(v);
        return Math.isNaN(f) ? fallback : f;
    }
}