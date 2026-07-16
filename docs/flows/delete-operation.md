# Data Flow: Delete — Удаление файла или папки

Диаграмма удаления с акцентом на очистку ресурсов. Помимо физического удаления через `fs.rmSync`, 
AssetPipelineService выполняет полную очистку связанных метаданных (.meta), билдов (.webp) 
и записей в базе данных (LowDB).

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant PP as ProjectPanel
    participant FSH as FileSystemHandlers
    participant FS as Node.js fs
    participant CH as Chokidar
    participant APS as AssetPipelineService
    participant ABP as AssetBrowserPanel

    Note over User, PP: Этап 1: Подтверждение и удаление
    User->>PP: Right Click → Delete → Confirm
    PP->>User: window.confirm('Delete?')
    PP->>FSH: ipc.invokeSafe("fs:delete", {path})
    Note over PP, FSH: IPC: Renderer → Main
    
    FSH->>FS: rmSync(path, recursive:true)
    FSH-->>PP: event.returnValue = {}
    Note over FSH, PP: IPC: Main → Renderer
    
    Note over PP, FSH: Этап 2: Обновление дерева
    PP->>PP: invalidateChildrenCache(parentPath)
    PP->>PP: setState({isLoading: true})
    PP->>FSH: readDir()
    FSH-->>PP: Список без удаленного элемента
    PP->>PP: setState({treeData: newData})
    PP-->>User: Элемент исчез из дерева
    
    par Параллельный процесс: Очистка ассетов
        FS->>CH: Детекция UNLINK
        CH->>APS: onFileDeleted
        APS->>APS: cleanupBuildFiles(path)
        APS->>APS: Удалить .meta и .webp
        APS->>APS: removeAssetByPath() из LowDB
        APS->>ABP: onAssetsChanged → Обновление превью
    end