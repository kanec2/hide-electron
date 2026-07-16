# Data Flow: External Changes — Изменения извне (OS File System)

Критически важная диаграмма, демонстрирующая рассинхронизацию между ProjectTree и AssetBrowser. 
Показывает, что Chokidar является единственным источником правды для изменений файловой системы, 
но ProjectPanel пока не подписан на эти события (требуется ручное обновление).

```mermaid
sequenceDiagram
    autonumber
    actor User as Пользователь (OS)
    participant CH as Chokidar
    participant APS as AssetPipelineService
    participant AW as AutoWindow
    participant ABP as AssetBrowserPanel
    participant PP as ProjectPanel

    Note over User, CH: Этап 1: Внешнее изменение
    User->>CH: Rename/Delete в проводнике Windows
    CH->>APS: Детекция UNLINK/ADD/CHANGE
    
    Note over APS, ABP: Этап 2: Реакция AssetPipeline
    APS->>APS: Обновить LowDB индекс
    APS->>AW: onAssetsChanged callback
    AW->>ABP: send("asset:changed")
    Note over AW, ABP: IPC: Main → Renderer
    ABP->>ABP: loadAssets()
    ABP->>ABP: setState({assets: newData})
    ABP-->>User: AssetBrowser обновлен ✅
    
    Note over PP: ⚠️ Проблема синхронизации
    PP--xPP: НЕ получает событие "asset:changed"
    Note right of PP: ProjectTree устарел ❌<br/>Требуется F5 или переоткрытие папки