# Data Flow: Create File/Folder — Создание файла или папки

Описывает процесс создания новых сущностей. Обратите внимание на ветвление логики 
в зависимости от типа создаваемого объекта (файл vs папка) и последующую реакцию 
AssetPipeline, которая игнорирует создание папок, обрабатывая только файлы.

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

    Note over User, PP: Этап 1: Ввод данных
    User->>PP: New File / New Folder
    PP->>User: window.prompt("Имя")
    PP->>PP: Вычислить newPath
    
    alt Тип: Папка
        PP->>FSH: ipc.invokeSafe("fs:createDirectory")
        FSH->>FS: ensureDirectoryExists (рекурсивно)
    else Тип: Файл
        PP->>FSH: ipc.invokeSafe("fs:writeText", content="")
        FSH->>FS: writeFileSync(path, "")
    end
    
    FSH-->>PP: event.returnValue = {}
    Note over FSH, PP: IPC: Main → Renderer
    
    Note over PP, FSH: Этап 2: Обновление дерева
    PP->>PP: invalidateChildrenCache(parentPath)
    PP->>PP: setState({isLoading: true})
    PP->>FSH: readDir()
    FSH-->>PP: Список с новым элементом
    PP->>PP: setState({treeData: newData})
    PP-->>User: Элемент появился в дереве
    
    par Параллельный процесс: Asset Pipeline
        FS->>CH: Детекция ADD
        CH->>APS: onFileAdded
        alt Это файл
            APS->>APS: importSingleAsset()
        else Это папка
            APS->>APS: Игнорировать
        end
        APS->>ABP: onAssetsChanged → Обновление превью
    end