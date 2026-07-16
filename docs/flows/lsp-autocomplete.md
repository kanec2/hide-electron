# Data Flow: LSP (Autocomplete / Diagnostics)

Диаграмма взаимодействия с Haxe Language Server через JSON-RPC. 
Показывает полный цикл запроса: от debounce в редакторе до парсинга stdout child process 
и возврата результата через IPC Promise.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant ME as Monaco Editor
    participant SVC as Haxe DI Service
    participant LSH as LanguageServerHandlers
    participant LSM as HaxeLanguageServerManager
    participant HLS as Haxe Language Server (Child)

    Note over User, ME: Этап 1: Ввод кода
    User->>ME: Печатает код
    ME->>ME: onDidChangeModelContent + debounce(300ms)
    ME->>SVC: Запрос автодополнения
    SVC->>LSH: ipcRenderer.invoke("lsp:request")
    Note over SVC, LSH: IPC: Renderer → Main
    
    Note over LSH, HLS: Этап 2: JSON-RPC коммуникация
    LSH->>LSM: Передать метод (textDocument/completion)
    LSM->>LSM: Генерация requestId + регистрация callback
    LSM->>HLS: Write JSON-RPC в stdin
    Note over LSM, HLS: Pipe → Child Process
    
    HLS->>HLS: Анализ AST проекта
    HLS->>LSM: Send Response в stdout
    Note over HLS, LSM: Pipe ← Child Process
    
    LSM->>LSM: Парсинг Content-Length + JSON
    LSM->>LSM: Найти callback по requestId
    LSM-->>LSH: Resolve Promise(result)
    Note over LSM, LSH: IPC: Main → Renderer
    
    LSH-->>ME: CompletionItems[]
    ME-->>User: Выпадающий список подсказок