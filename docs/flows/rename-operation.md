# Data Flow: Переименование файла и обновление Asset Pipeline

Эта диаграмма описывает поток данных при переименовании актива в дереве проекта, включая IPC-взаимодействие и параллельную реакцию Chokidar.

```mermaid
sequenceDiagram
    actor User
    participant ReactArborist
    participant ProjectPanel as ProjectPanel (Renderer)
    participant ElectronBackend as ElectronBackend (Renderer)
    participant AutoWindow as AutoWindow (Main)
    participant FS as Node.js fs
    participant Chokidar
    participant AssetPipeline as AssetPipelineService

    User->>ReactArborist: Правый клик → Rename → Enter
    ReactArborist->>ProjectPanel: onRename({id, name, node})
    ProjectPanel->>ProjectPanel: Вычисляет newPath = replaceNameInPath(...)
    ProjectPanel->>ElectronBackend: ipc.invokeSafe("fs:rename", {oldPath, newPath})
    
    Note over ElectronBackend, AutoWindow: IPC: Renderer → Main
    ElectronBackend->>AutoWindow: Обработчик "fs:rename"
    AutoWindow->>FS: renameSync(oldPath, newPath)
    AutoWindow->>FS: renameSync(old.meta, new.meta)
    AutoWindow->>FS: renameSync(old.webp, new.webp)
    AutoWindow-->>ElectronBackend: event.returnValue = {}
    
    Note over AutoWindow, ProjectPanel: IPC: Main → Renderer (ответ)
    ElectronBackend-->>ProjectPanel: Promise resolved
    ProjectPanel->>ProjectPanel: refreshParentDirectory()
    ProjectPanel->>ProjectPanel: setState({isLoading: true, treeData: newData})
    ProjectPanel-->>User: UI перерисован, папка раскрыта

    par Параллельный процесс: File System Watcher
        FS->>Chokidar: События 'unlink' (старый) и 'add' (новый)
        Chokidar->>AssetPipeline: onFileDeleted() → cleanupBuildFiles()
        Chokidar->>AssetPipeline: onFileAdded() → importSingleAsset()
        AssetPipeline->>AutoWindow: onAssetsChanged callback
        AutoWindow->>ProjectPanel: window.webContents.send("asset:changed")
        Note over AutoWindow, ProjectPanel: IPC: Main → Renderer (event)
        ProjectPanel->>ProjectPanel: loadAssets() → Обновление превью
        ProjectPanel-->>User: AssetBrowser обновлен
    end
```