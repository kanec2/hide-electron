# Data Flow: Lazy Load — Раскрытие папки (onToggle)

Эта диаграмма описывает механизм ленивой загрузки содержимого директорий. 
Вместо загрузки всего дерева проекта при старте, приложение запрашивает детей узла 
только в момент его раскрытия пользователем. Это критически важно для производительности 
при работе с большими проектами.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant RA as ReactArborist
    participant PP as ProjectPanel
    participant PTS as ProjectTreeService
    participant FSH as FileSystemHandlers
    participant FS as Node.js fs

    Note over User, RA: Этап 1: Взаимодействие
    User->>RA: Клик на стрелку папки
    RA->>PP: onToggle(id)
    
    Note over PP, PTS: Этап 2: Проверка кэша
    PP->>PP: Найти узел в state.treeData
    alt Узел уже загружен (isLoaded == true)
        RA->>RA: Раскрыть узел локально
    else Узел не загружен
        PP->>PP: setState({isLoading: true})
        Note right of PP: Показ ⏳ индикатора
        PP->>PTS: readDir(node.path)
        PTS->>FSH: ipc.invokeSafe("project:readDir")
        Note over PTS, FSH: IPC: Renderer → Main
        
        FSH->>FS: readdirSync(targetDir)
        FSH-->>PTS: Массив children
        Note over FSH, PTS: IPC: Main → Renderer
        
        PTS->>PTS: Преобразование в ArboristNode[]
        PTS-->>PP: Callback с newNodes
    end
    
    Note over PP, RA: Этап 3: Обновление UI
    PP->>PP: updateNodeInTree(id, {children})
    PP->>PP: setState({treeData: finalData})
    PP->>RA: treeRef.open(id) + delay(50ms)
    RA-->>User: Отображение содержимого папки