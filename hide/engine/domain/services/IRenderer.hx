package hide.engine.domain.services;
import hide.engine.domain.entities.SceneObject;
/**
 * Порт рендерера. НЕ знает про Heaps/Three.js/WebGL.
 */
 
interface IRenderer {
    function init(container:Dynamic):Void;
    function renderScene(root:SceneObject):Void;
    function onResize(width:Int, height:Int):Void;
    function dispose():Void;
}