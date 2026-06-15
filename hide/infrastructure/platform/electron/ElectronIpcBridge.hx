package hide.infrastructure.platform.electron;

import tink.core.Future;
import tink.core.Outcome;
import tink.core.Error;
import electron.renderer.IpcRenderer;
import js.lib.Promise;
import hx.injection.Service;

using tink.CoreApi;
/**
 * Централизованный мост для IPC-вызовов между Renderer и Main процессами.
 * Все адаптеры (FileDialog, FileSystem, Window) используют этот класс.
 */
class ElectronIpcBridge implements Service {
    private var ipcRenderer:Dynamic;

    public function new() {
    }

    /**
     * Универсальный метод для IPC-вызова с возвратом Future.
     * Использует типизированный Promise из hxelectron.
     */
    public function invoke<T>(channel:String, ?args:Dynamic):Future<Outcome<T, Error>> {
        return Future.async(function(trigger) {
            // hxelectron возвращает js.lib.Promise
            var promise:js.lib.Promise<Dynamic> = IpcRenderer.invoke(channel, args);
            
            promise.then(function(result:Dynamic) {
                trigger(Outcome.Success(cast result));
                return null;
            }).catchError(function(err:Dynamic) {
                trigger(Outcome.Failure(new Error(500, Std.string(err))));
                return null;
            });
        });
    }

    /**
     * Упрощённая версия — возвращает значение или null при ошибке.
     */
    public function invokeSafe<T>(channel:String, ?args:Dynamic):Future<Null<T>> {
        return Future.async(function(trigger) {
            var promise:js.lib.Promise<Dynamic> = IpcRenderer.invoke(channel, args);
            
            promise.then(function(result:Dynamic) {
                trigger(cast result);
                return null;
            }).catchError(function(err:Dynamic) {
                trace('[IPC Error] $channel: $err');
                trigger(null);
                return null;
            });
        });
    }

    /**
     * Синхронный IPC-вызов (блокирующий).
     */
    public function invokeSync<T>(channel:String, ?args:Dynamic):T {
        return IpcRenderer.sendSync(channel, args);
    }

    /**
     * Подписка на события из Main процесса.
     */
    public function on(channel:String, callback:Dynamic->Void):Void {
        IpcRenderer.on(channel, function(event:Dynamic, data:Dynamic) {
            callback(data);
        });
    }

    /**
     * Отписка от событий.
     */
    public function off(channel:String, ?callback:Dynamic->Void):Void {
        if (callback != null) {
            IpcRenderer.removeListener(channel, callback);
        } else {
            IpcRenderer.removeAllListeners(channel);
        }
    }
}