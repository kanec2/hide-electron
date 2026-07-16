# Data Flow: Инициализация дерева проекта при открытии

Эта диаграмма описывает процесс загрузки корневой директории проекта в UI. 
Она показывает полный цикл от запуска приложения до рендеринга первого узла дерева, 
включая инициализацию сервисов, IPC-запрос списка файлов и преобразование данных 
для ReactArborist.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant EM as ElectronMain
    participant SL as ServiceLocator
    participant AW as AutoWindow
    participant PS as ProjectService
    participant AP as AssetPipeline
    participant PP as ProjectPanel
    participant FSH as FileSystemHandlers
    participant FS as Node.js fs
    participant PTS as ProjectTreeService
    participant RA as ReactArborist

    Note over User, EM: Этап 1: Инициализация
    User->>EM: Запуск приложения
    EM->>SL: init()
    EM->>AW: start({onReady: startup})
    
    Note over PS, AP: Этап 2: Загрузка проекта
    User->>PS: Открывает проект
    PS->>PS: Создает объект Project
    PS->>AP: backend init (через IPC)
    
    Note over PP, FSH: Этап 3: Чтение корня (IPC)
    PP->>PP: componentDidMount()
    PP->>PP: loadRoot()
    PP->>FSH: ipc.invokeSafe("project:readDir")
    Note right of PP: Renderer → Main
    
    FSH->>AP: Получает projectRoot
    FSH->>FS: readdirSync(targetDir)
    FSH->>FSH: Сортировка: папки → файлы
    FSH-->>PP: Возврат массива entries
    Note left of FSH: Main → Renderer
    
    Note over PTS, RA: Этап 4: Рендеринг UI
    PP->>PTS: readDir(entries)
    PTS->>PTS: Преобразование в ArboristNode[]
    PTS-->>PP: Callback с nodes
    PP->>PP: setState({treeData})
    PP->>RA: Trigger re-render
    RA->>RA: renderNode(api)
    RA-->>User: Отображение дерева