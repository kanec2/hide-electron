// hide/domain/entities/SceneComponent.hx
package hide.engine.domain.entities;

/**
Базовый интерфейс для компонентов (MeshRenderer, Rigidbody, Light и т.д.)
*/
interface SceneComponent {
    var id:String;
    var name:String;
    function clone():SceneComponent;
}