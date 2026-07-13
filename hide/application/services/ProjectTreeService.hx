// hide/application/services/ProjectTreeService.hx
package hide.application.services;

import hide.infrastructure.platform.electron.ElectronIpcBridge;
import hide.shared.types.IpcResponse;
import hx.injection.Service;
import tink.core.*;
using tink.CoreApi;

typedef TreeNode = {
    var name:String;
    var path:String;
    var relativePath:String;
    var isDirectory:Bool;
    var extension:Null<String>;
    var ?children:Array<TreeNode>; // Заполняется при раскрытии
    var ?isLoading:Bool;           // Флаг загрузки для UI
}

class ProjectTreeService implements Service {
    private var ipcBridge:ElectronIpcBridge;
    //private var cache:Map<String, Array<ProjectNode>> = new Map();

    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }

    /**
     * Получает дерево проекта. 
     * Если folder == null, возвращает корень.
     */
    /**
     * Загружает содержимое папки. 
     * Если path == null, загружает корень проекта.
     */
    public function readDir(?path:String):Future<Array<TreeNode>> {
        return ipcBridge.invokeSafe("project:readDir", { path: path })
            .map(function(response) {
                if (response != null && response.success) {
                    // Явное приведение типа, чтобы компилятор не ругался
                    var nodes:Array<TreeNode> = cast response.data;
                    trace(' [Service] Received ${nodes.length} nodes for: $path');
                    return nodes;
                }
                trace('⚠️ [Service] Failed to read dir: $path');
                return [];
            });
    }

    public function invalidateCache():Void {
        //cache = new Map();
    }
}