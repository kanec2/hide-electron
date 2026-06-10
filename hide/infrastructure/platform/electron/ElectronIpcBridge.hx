package hide.infrastructure.platform.electron;

import tink.core.Future;
import tink.core.Outcome;

/**
 * Централизованный мост для IPC-вызовов между Renderer и Main процессами.
 * Все адаптеры (FileDialog, FileSystem, Window) используют этот класс.
 */
class ElectronIpcBridge {
    private var ipcRenderer:Dynamic;
    
    public function new() {
        var electron = js.Node.require("electron");
        ipcRenderer = electron.ipcRenderer;
    }
    
    /**
     * Универсальный метод для IPC-вызова с возвратом Future.
     */
    public function invoke<T>(channel:String, ?args:Dynamic):Future<Outcome<T, Error>> {
        return Future.async(function(trigger) {
            ipcRenderer.invoke(channel, args)
                .then(function(result:Dynamic) {
                    trigger(Success(cast result));
                })
                .catchError(function(err:Dynamic) {
                    trigger(Failure(new Error(Std.string(err))));
                });
        });
    }
    
    /**
     * Упрощённая версия — возвращает значение или null при ошибке.
     */
    public function invokeSafe<T>(channel:String, ?args:Dynamic):Future<Null<T>> {
        return Future.async(function(trigger) {
            ipcRenderer.invoke(channel, args)
                .then(function(result:Dynamic) {
                    trigger(cast result);
                })
                .catchError(function(err:Dynamic) {
                    trace('[IPC Error] $channel: $err');
                    trigger(null);
                });
        });
    }
    
    /**
     * Синхронный IPC-вызов (блокирующий).
     * Используется только там, где это критично (например, exists()).
     */
    public function invokeSync<T>(channel:String, ?args:Dynamic):T {
        return ipcRenderer.sendSync(channel, args);
    }

    /**
     * Подписка на события из Main процесса.
     */
    public function on(channel:String, callback:Dynamic->Void):Void {
        ipcRenderer.on(channel, function(event, data) {
            callback(data);
        });
    }
    
    /**
     * Отписка от событий.
     */
    public function off(channel:String, ?callback:Dynamic->Void):Void {
        if (callback != null) {
            ipcRenderer.removeListener(channel, callback);
        } else {
            ipcRenderer.removeAllListeners(channel);
        }
    }
}