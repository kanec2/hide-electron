# Data Flow: Shader Editor Preview

Локальный поток данных внутри Renderer процесса. Демонстрирует интеграцию LiteGraph.js 
с движком Heaps для мгновенной визуализации шейдеров без IPC-накладных расходов.

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь
    participant LG as LiteGraph.js
    participant SEP as ShaderEditorPanel
    participant HE as Heaps Engine
    participant SPR as ShaderPreviewRenderer
    participant GL as WebGL Canvas

    Note over User, LG: Этап 1: Редактирование графа
    User->>LG: Изменение значения ноды
    LG->>LG: onAfterChange trigger
    LG->>SEP: Генерация HLSL/GLSL кода
    
    Note over SEP, HE: Этап 2: Компиляция
    SEP->>SEP: Обновление состояния редактора
    SEP->>HE: Компиляция шейдера (HXSL)
    alt Ошибка компиляции
        HE->>SEP: Показать diagnostic в UI
    else Успех
        HE->>HE: Применить материал к PBR Sphere
    end
    
    Note over SPR, GL: Этап 3: Рендеринг
    SPR->>SPR: Перерисовка сцены
    SPR->>GL: OrbitControls update + Render Frame
    GL-->>User: Обновленное превью шейдера