# Data Flow: Drag & Drop — Перемещение файлов

Диаграмма описывает сложный сценарий перемещения, который затрагивает две директории одновременно. 
Обратите внимание на двойную реакцию AssetPipeline: сначала удаляются билды старого пути, 
затем импортируются новые по целевому пути.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant RA as ReactArborist
    participant PP as ProjectPanel
    participant FSH as FileSystemHandlers (Main)
    participant FS as Node.js fs
    participant CH as Chokidar
    participant APS as AssetPipelineService
    participant AW as AutoWindow
    participant ABP as AssetBrowserPanel

    Note over User, RA: Этап 1: Инициация перемещения
    User->>RA: Drag file → Drop on folder
    RA->>PP: onMove({dragIds, dragNodes, parentNode})
    PP->>PP: Вычислить destPath = target + "/" + fileName
    
    loop Для каждого перемещаемого файла
        PP->>FSH: ipc.invokeSafe("fs:move", src, dest)
        Note over PP, FSH: IPC: Renderer → Main
        FSH->>FS: renameSync(sourcePath, destPath)
        FSH-->>PP: event.returnValue = {}
        Note over FSH, PP: IPC: Main → Renderer
    end

    Note over PP, FSH: Этап 2: Обновление дерева (Source + Target)
    PP->>PP: invalidateChildrenCache(srcParentPath)
    PP->>PP: invalidateChildrenCache(targetPath)
    PP->>PP: setState({isLoading: true})
    
    par Параллельное чтение двух директорий
        PP->>FSH: readDir(srcParentPath)
        FSH-->>PP: Обновленный список источника
        and
        PP->>FSH: readDir(targetPath)
        FSH-->>PP: Обновленный список цели
    end
    
    PP->>PP: setState({treeData: newData})
    PP-->>User: Файл визуально перемещен в дереве

    rect rgb(240, 255, 240)
        Note over FS, ABP: Этап 3: Реакция Asset Pipeline (Параллельно)
        FS->>CH: Детекция UNLINK (старый путь)
        FS->>CH: Детекция ADD (новый путь)
        
        CH->>APS: onFileDeleted(oldPath)
        APS->>APS: cleanupBuildFiles(oldPath)
        
        CH->>APS: onFileAdded(newPath)
        APS->>APS: importSingleAsset(newPath)
        
        APS->>AW: onAssetsChanged callback
        AW->>ABP: send("asset:changed")
        Note over AW, ABP: IPC: Main → Renderer
        
        ABP->>ABP: loadAssets()
        ABP-->>User: AssetBrowser обновлен
    end