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

typedef InspectorProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef InspectorState = {
    var selectedObject: Null<SceneObject>;
    var version: Int; // триггер для перерисовки при изменениях
}

class InspectorPanel extends BaseReactComponent<InspectorProps, InspectorState> {
    public function new() {
        super();
        state = { selectedObject: null, version: 0 };
    }

    override function componentDidMount(): Void {
        var eventBus = UseService.eventBus();
        var scene = UseService.sceneService();

        // 1. Подписываемся на выбор объекта
        subscribe(eventBus, ObjectSelected, function(e:ObjectSelected) {
            var obj = e.objectId != null ? scene.getObject(e.objectId) : null;
            setState({ selectedObject: obj, version: state.version + 1 });
        });

        // 2. Подписываемся на изменения объекта (обновляем UI)
        subscribe(eventBus, ObjectChanged, function(e:ObjectChanged) {
            if (state.selectedObject != null && state.selectedObject.id == e.objectId) {
                var fresh = scene.getObject(e.objectId);
                setState({ selectedObject: fresh, version: state.version + 1 });
            }
        });

        // 3. Если уже что-то выбрано при монтировании — покажем сразу
        var current = scene.getSelected();
        if (current != null) {
            setState({ selectedObject: current, version: state.version + 1 });
        }
    }

    override function render(): ReactElement {
        var obj = state.selectedObject;

        var header: ReactElement = if (obj != null) {
            jsx('
                <div style={{padding:"8px",background:"#2a2a2a",borderRadius:"3px",marginBottom:"8px"}}>
                    <div style={{display:"flex",alignItems:"center",gap:"8px"}}>
                        <input type="checkbox" defaultChecked={obj.isActive}
                            onChange={function(_) toggleActive(obj.id)} />
                        <b style={{color:"#fff"}}>{obj.name}</b>
                        <span style={{marginLeft:"auto",color:"#888",fontSize:"11px"}}>
                            id: {obj.id}
                        </span>
                    </div>
                </div>
            ');
        } else {
            jsx('<div style={{padding:"20px",textAlign:"center",color:"#888"}}>No object selected</div>');
        };

        var componentsList: ReactElement = if (obj != null) {
            jsx('
                <div style={{overflowY:"auto",maxHeight:"calc(100% - 60px)"}}>
                    {renderTransform(obj)}
                    {[for (c in obj.components) renderComponent(obj.id, c)]}
                    <div style={{marginTop:"10px",textAlign:"center"}}>
                        <button style={{background:"#4a4a4a",color:"#fff",border:"1px solid #555",
                            padding:"4px 12px",borderRadius:"3px",cursor:"pointer"}}>
                            Add Component
                        </button>
                    </div>
                </div>
            ');
        } else {
            jsx('<div></div>');
        };

        return jsx('
            <div style={{padding:"10px",color:"#d4d4d4",background:"#383838",
                height:"100%",fontFamily:"sans-serif",fontSize:"13px"}}>
                {header}
                {componentsList}
            </div>
        ');
    }

    // ===== Transform (всегда есть у каждого объекта) =====
    private function renderTransform(obj: SceneObject): ReactElement {
        var t = obj.transform;
        return jsx('
            <div style={{background:"#2a2a2a",borderRadius:"3px",marginBottom:"6px"}}>
                <div style={{padding:"6px 8px",background:"#3a3a3a",fontWeight:"bold",
                    borderBottom:"1px solid #222"}}>
                    🔽 Transform
                </div>
                <div style={{padding:"8px"}}>
                    {renderVector3("Position", t.x, t.y, t.z, function(x,y,z) setTransform(obj.id, x,y,z, t.rotX,t.rotY,t.rotZ, t.scaleX,t.scaleY,t.scaleZ))}
                    {renderVector3("Rotation", t.rotX, t.rotY, t.rotZ, function(x,y,z) setTransform(obj.id, t.x,t.y,t.z, x,y,z, t.scaleX,t.scaleY,t.scaleZ))}
                    {renderVector3("Scale", t.scaleX, t.scaleY, t.scaleZ, function(x,y,z) setTransform(obj.id, t.x,t.y,t.z, t.rotX,t.rotY,t.rotZ, x,y,z))}
                </div>
            </div>
        ');
    }

    // ===== Компоненты (MeshRenderer, Rigidbody, ...) =====
    private function renderComponent(objId: String, comp: hide.engine.domain.entities.SceneComponent): ReactElement {
        return switch (Type.getClassName(Type.getClass(comp))) {
            case "hide.engine.domain.entities.MeshRenderer":
                var m: MeshRenderer = cast comp;
                jsx('
                    <div key={comp.id} style={{background:"#2a2a2a",borderRadius:"3px",marginBottom:"6px"}}>
                        <div style={{padding:"6px 8px",background:"#3a3a3a",fontWeight:"bold",borderBottom:"1px solid #222"}}>
                            🔽 Mesh Renderer
                        </div>
                        <div style={{padding:"8px"}}>
                            {renderStringField("Mesh", m.meshPath, function(v) setMesh(objId, v, m.materialPath))}
                            {renderStringField("Material", m.materialPath, function(v) setMesh(objId, m.meshPath, v))}
                        </div>
                    </div>
                ');
            case "hide.engine.domain.entities.Rigidbody":
                var r: Rigidbody = cast comp;
                jsx('
                    <div key={comp.id} style={{background:"#2a2a2a",borderRadius:"3px",marginBottom:"6px"}}>
                        <div style={{padding:"6px 8px",background:"#3a3a3a",fontWeight:"bold",borderBottom:"1px solid #222"}}>
                            🔽 Rigidbody
                        </div>
                        <div style={{padding:"8px"}}>
                            {renderNumberField("Mass", r.mass, function(v) setRigidbody(objId, v, r.useGravity))}
                            <div style={{display:"flex",gap:"4px",marginBottom:"4px"}}>
                                <span style={{width:"60px",color:"#aaa"}}>Gravity</span>
                                <input type="checkbox" defaultChecked={r.useGravity}
                                    onChange={function(_) setRigidbody(objId, r.mass, !r.useGravity)} />
                            </div>
                        </div>
                    </div>
                ');
            default:
                jsx('
                    <div key={comp.id} style={{background:"#2a2a2a",borderRadius:"3px",marginBottom:"6px",padding:"8px",color:"#888"}}>
                        Unknown component: {comp.name}
                    </div>
                ');
        };
    }

    // ===== Поля ввода =====
    private function renderVector3(label: String, x: Float, y: Float, z: Float, onChange: Float->Float->Float->Void): ReactElement {
        return jsx('
            <div style={{display:"flex",gap:"4px",marginBottom:"4px"}}>
                <span style={{width:"60px",color:"#aaa"}}>{label}</span>
                <input defaultValue={x} style={{flex:1,background:"#1a1a1a",border:"1px solid #555",color:"#fff",padding:"2px 4px",borderRadius:"2px"}}
                    onBlur={function(e) onChange(Std.parseFloat(e.target.value), y, z)} />
                <input defaultValue={y} style={{flex:1,background:"#1a1a1a",border:"1px solid #555",color:"#fff",padding:"2px 4px",borderRadius:"2px"}}
                    onBlur={function(e) onChange(x, Std.parseFloat(e.target.value), z)} />
                <input defaultValue={z} style={{flex:1,background:"#1a1a1a",border:"1px solid #555",color:"#fff",padding:"2px 4px",borderRadius:"2px"}}
                    onBlur={function(e) onChange(x, y, Std.parseFloat(e.target.value))} />
            </div>
        ');
    }

    private function renderStringField(label: String, value: String, onChange: String->Void): ReactElement {
        return jsx('
            <div style={{display:"flex",gap:"4px",marginBottom:"4px"}}>
                <span style={{width:"60px",color:"#aaa"}}>{label}</span>
                <input defaultValue={value} style={{flex:1,background:"#1a1a1a",border:"1px solid #555",color:"#fff",padding:"2px 4px",borderRadius:"2px"}}
                    onBlur={function(e) onChange(e.target.value)} />
            </div>
        ');
    }

    private function renderNumberField(label: String, value: Float, onChange: Float->Void): ReactElement {
        return jsx('
            <div style={{display:"flex",gap:"4px",marginBottom:"4px"}}>
                <span style={{width:"60px",color:"#aaa"}}>{label}</span>
                <input defaultValue={value} style={{flex:1,background:"#1a1a1a",border:"1px solid #555",color:"#fff",padding:"2px 4px",borderRadius:"2px"}}
                    onBlur={function(e) onChange(Std.parseFloat(e.target.value))} />
            </div>
        ');
    }

    // ===== Команды в SceneService =====
    private function setTransform(objId: String,
        px:Float, py:Float, pz:Float,
        rx:Float, ry:Float, rz:Float,
        sx:Float, sy:Float, sz:Float): Void {
        UseService.sceneService().setTransform(objId,
            new Transform(px, py, pz, rx, ry, rz, sx, sy, sz));
    }

    private function setMesh(objId: String, meshPath: String, matPath: String): Void {
        var obj = UseService.sceneService().getObject(objId);
        if (obj == null) return;
        obj.removeComponent(obj.getComponent(MeshRenderer).id);
        obj.addComponent(new MeshRenderer(meshPath, matPath));
        UseService.eventBus().publish(ObjectChanged, new ObjectChanged(objId));
    }

    private function setRigidbody(objId: String, mass: Float, gravity: Bool): Void {
        var obj = UseService.sceneService().getObject(objId);
        if (obj == null) return;
        var old = obj.getComponent(Rigidbody);
        if (old != null) obj.removeComponent(old.id);
        obj.addComponent(new Rigidbody(mass, gravity));
        UseService.eventBus().publish(ObjectChanged, new ObjectChanged(objId));
    }

    private function toggleActive(objId: String): Void {
        var obj = UseService.sceneService().getObject(objId);
        if (obj == null) return;
        obj.isActive = !obj.isActive;
        UseService.eventBus().publish(ObjectChanged, new ObjectChanged(objId));
    }
}