// hide/domain/services/ISceneService.hx
package hide.engine.domain.services;

import hide.engine.domain.entities.SceneComponent;
import hide.engine.domain.entities.SceneObject;
import hide.engine.domain.entities.Transform;
import hx.injection.Service;

/**
Доменный порт для управления сценой.
НЕ знает ни про UI, ни про рендер (Heaps/Three.js).
*/
interface ISceneService extends Service {
    // Запросы (Queries)
    function getRoot():SceneObject;
    function getObject(id:String):Null<SceneObject>;
    function getSelected():Null<SceneObject>;
    function getAll():Array<SceneObject>;

    // Команды (Commands)
    function select(id:String):Void;
    function deselect():Void;
    function rename(id:String, newName:String):Void;
    function setTransform(id:String, transform:Transform):Void;
    function setMeshRenderer(id:String, meshPath:String, materialPath:String):Void;
    function setRigidbody(id:String, mass:Float, useGravity:Bool):Void;
    function setActive(id:String, active:Bool):Void;
    
    function addComponent(id:String, component:SceneComponent):Void;
    function removeComponent(id:String, componentId:String):Void;



    // События
    function onObjectSelected(callback:String->Void):Void;
    function onObjectChanged(callback:String->Void):Void;
    function onSceneChanged(callback:Void->Void):Void;
}