# IPC Bridge Architecture

## Схема взаимодействия
IPC слой реализует паттерн Bridge, предотвращая прямые зависимости Renderer от Node.js API.

```mermaid
classDiagram
    class IpcBridge {
        +invokeSafe(channel: String, args: Dynamic): Promise~Dynamic~
        -serializeError(error: Dynamic): ErrorPayload
    }
    
    class AutoWindow {
        +registerHandlers(): Void
        -setupIpc(): Void
    }
    
    class FileSystemHandlers {
        +onRename(event, args): Void
        +onReadDir(event, args): Array~Entry~
        +onDelete(event, args): Void
    }
    
    class ProjectPanel {
        -handleRename(args): Void
        -loadRoot(): Void
    }

    ProjectPanel --> IpcBridge : uses
    IpcBridge ..> AutoWindow : IPC Invoke
    AutoWindow --> FileSystemHandlers : delegates
    FileSystemHandlers --> NodeFS : calls