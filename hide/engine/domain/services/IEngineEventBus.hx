// hide/engine/domain/services/IEngineEventBus.hx
package hide.engine.domain.services;

import hx.injection.Service;

/**
 * Изолированный EventBus для движка.
 * НЕ зависит от shared.events IDE — движок остаётся самодостаточным.
 */
interface IEngineEventBus extends Service {
    // === Подписка ===
    function onObjectSelected(callback:String->Void):Void;
    function onObjectChanged(callback:String->Void):Void;
    function onSceneChanged(callback:Void->Void):Void;
    
    // === Публикация ===
    function emitObjectSelected(id:Null<String>):Void;
    function emitObjectChanged(id:String):Void;
    function emitSceneChanged():Void;
}