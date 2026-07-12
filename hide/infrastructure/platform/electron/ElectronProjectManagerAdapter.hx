package hide.infrastructure.platform.electron;

import hide.domain.services.IProjectManager;
import hide.domain.entities.Project;
import hide.domain.valueobjects.FilePath;
import tink.core.Future;
import hx.injection.Service;

class ElectronProjectManagerAdapter implements IProjectManager implements Service {
    private var ipcBridge:ElectronIpcBridge;

    public function new(ipcBridge:ElectronIpcBridge) {
        this.ipcBridge = ipcBridge;
    }

    public function openProject(path:FilePath):Future<Project> {
        // Вызываем метод на бэкенде
        return ipcBridge.invokeSafe("project:open", path.toString())
            .map(function(data:Dynamic) {
                if (data == null || !data.success) {
                    throw "Failed to open project at " + path.toString();
                }
                // Здесь можно распарсить ответ и вернуть объект Project, 
                // если бэкенд возвращает его метаданные
                return Project.fromJson(data.content, path); 
            });
    }

    public function closeProject():Future<Bool> {
        return ipcBridge.invokeSafe("project:close", null)
            .map(function(res:Dynamic) return res != null && res.success);
    }

    public function saveProject(project:Project):Future<Bool> {
        return ipcBridge.invokeSafe("project:save", {
            path: project.rootPath.toString(),
            content: project.toJson()
        }).map(function(res:Dynamic) return res != null && res.success);
    }

    public function createProject(name:String, path:FilePath):Future<Project> {
        return ipcBridge.invokeSafe("project:create", {
            name: name,
            path: path.toString()
        }).map(function(data:Dynamic) {
            // Логика создания структуры папок и файла проекта
            return null; // TODO: вернуть созданный проект
        });
    }

    public function getRecentProjects():Future<Array<String>> {
        return ipcBridge.invokeSafe("project:getRecent", null)
            .map(function(data:Dynamic) {
                if (data == null) return [];
                return data.paths;
            });
    }
}