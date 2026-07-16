# Data Flow: Project Save/Load — Сохранение и загрузка состояния

Описывает сериализацию состояния IDE (GoldenLayout, открытые файлы, курсоры) 
в `.hideproj` файл и обратный процесс восстановления интерфейса при открытии проекта.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant MS as MenuService
    participant PS as ProjectService
    participant GL as GoldenLayout
    participant FSH as FileSystemHandlers
    participant FS as Node.js fs

    rect rgb(240, 248, 255)
        Note over User, MS: 🟦 SAVE OPERATION
        User->>MS: Ctrl+S / File → Save
        MS->>PS: projectService.save()
        PS->>GL: getState() → JSON config
        PS->>PS: Собрать открытые файлы + курсоры
        PS->>FSH: ipc.invokeSafe("fs:writeText")
        Note over PS, FSH: IPC: Renderer → Main
        
        FSH->>FS: writeFileSync(path, content)
        FSH-->>PS: event.returnValue = {}
        Note over FSH, PS: IPC: Main → Renderer
        
        PS->>PS: Показать "Saved" в StatusBar
        PS-->>User: Подтверждение сохранения
    end

    rect rgb(255, 248, 240)
        Note over User, MS: 🟧 LOAD OPERATION
        User->>MS: File → Open → .hideproj
        MS->>PS: loadProject(projectPath)
        PS->>FSH: ipc.invokeSafe("fs:readText")
        Note over PS, FSH: IPC: Renderer → Main
        
        FSH->>FS: readFileSync(path, utf-8)
        FSH-->>PS: { content: "..." }
        Note over FSH, PS: IPC: Main → Renderer
        
        PS->>PS: Парсинг JSON проекта
        PS->>GL: restoreState(config)
        PS->>PS: Открыть файлы + загрузить ассеты
        PS-->>User: Интерфейс восстановлен
    end