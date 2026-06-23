package hide.engine.domain.services;
import hide.engine.domain.entities.SceneObject;
import hx.injection.Service;
/**
 * Порт рендерера. НЕ знает про Heaps/Three.js/WebGL.
 */
 
interface IRenderer extends Service {
    function init():Void;
    //function renderScene(root:SceneObject):Void;
    function onResize(width:Int, height:Int):Void;
    function dispose():Void;
}