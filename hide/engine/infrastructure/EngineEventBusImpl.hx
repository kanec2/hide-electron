// hide/engine/infrastructure/EngineEventBusImpl.hx
package hide.engine.infrastructure;

import hide.engine.domain.services.IEngineEventBus;
import hx.injection.Service;

/**
 * Реализация IEngineEventBus.
 * Простой список коллбэков — без зависимостей от IDE.
 */
class EngineEventBusImpl implements IEngineEventBus implements Service {
    private var objectSelectedCallbacks:Array<String->Void>;
    private var objectChangedCallbacks:Array<String->Void>;
    private var sceneChangedCallbacks:Array<Void->Void>;
    
    public function new() {
        objectSelectedCallbacks = [];
        objectChangedCallbacks = [];
        sceneChangedCallbacks = [];
    }
    
    // === Подписка ===
    public function onObjectSelected(callback:String->Void):Void {
        objectSelectedCallbacks.push(callback);
    }
    
    public function onObjectChanged(callback:String->Void):Void {
        objectChangedCallbacks.push(callback);
    }
    
    public function onSceneChanged(callback:Void->Void):Void {
        sceneChangedCallbacks.push(callback);
    }
    
    // === Публикация ===
    public function emitObjectSelected(id:Null<String>):Void {
        // Копируем массив, чтобы отписка во время итерации не сломала цикл
        var snapshot = objectSelectedCallbacks.copy();
        for (cb in snapshot) cb(id);
    }
    
    public function emitObjectChanged(id:String):Void {
        var snapshot = objectChangedCallbacks.copy();
        for (cb in snapshot) cb(id);
    }
    
    public function emitSceneChanged():Void {
        var snapshot = sceneChangedCallbacks.copy();
        for (cb in snapshot) cb();
    }
}