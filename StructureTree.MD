## 📁 Структура проекта `hide_js/`

### 🔷 Domain (`hide/domain/`) — Ядро бизнеса (0 зависимостей)
- `entities/` — Сущности предметной области
  - `Project.hx` → `class Project { id, name, rootPath, ... }`
  - `Resource.hx` → `class Resource { id, path, type, metadata }`
  - `Database.hx` → `class Database { tables, schemas, ... }`
  - `LayoutConfig.hx` → `typedef LayoutConfig = { panels: [...], active: String }`
  - `UserSettings.hx` → `class UserSettings { theme, fontSize, ... }`
- `valueobjects/` — Неизменяемые объекты-значения
  - `FilePath.hx` → `abstract FilePath(String) { function validate():Bool; }`
  - `ResourceId.hx` → `abstract ResourceId(String)`
  - `ScreenBounds.hx` → `typedef ScreenBounds = { x:Int, y:Int, w:Int, h:Int }`
- `enums/` — Типобезопасные перечисления
  - `ResourceType.hx` → `enum ResourceType { Texture; Model; Shader; Cdb; ... }`
  - `ViewType.hx` → `enum ViewType { ModelEditor; PrefabEditor; CdbTable; ... }`
  - `WindowEvent.hx` → `enum WindowEvent { Focus; Blur; Resize; Close; ... }`
  - `MenuItemType.hx` → `enum MenuItemType { Normal; Checkbox; Separator; Submenu }`
- `services/` — Интерфейсы (порты) для внешних зависимостей
  - `IWindowManager.hx` → `interface { resizeBy(), moveTo(), onEvent()... }`
  - `IClipboardService.hx` → `interface { setText(), getText(), hasFormat()... }`
  - `IFileSystem.hx` → `interface { exists(), readText(), writeBytes()... }`
  - `IResourceLoader.hx` → `interface { loadTexture(), loadShader(), cache()... }`
  - `ILayoutEngine.hx` → `interface { openPanel(), saveState(), restoreState()... }`
  - `IEventBus.hx` → `interface { publish(), subscribe(), unsubscribe()... }`
- `exceptions/` — Бизнес-исключения
  - `ProjectLoadError.hx` → `class ProjectLoadError extends Error { ... }`
  - `ResourceNotFoundError.hx` → `class ResourceNotFoundError extends Error { ... }`
  - `InvalidConfigError.hx` → `class InvalidConfigError extends Error { ... }`

### 🟩 Application (`hide/application/`) — Бизнес-логика приложения (Use-Cases)
- `services/` — Реализация сервисов (оркестрация)
  - `WindowService.hx` → `class WindowService implements IWindowManager`
  - `MenuService.hx` → `class MenuService { buildFromTemplate(), setClipboard()... }`
  - `LayoutService.hx` → `class LayoutService implements ILayoutEngine`
  - `ProjectService.hx` → `class ProjectService { load(), save(), switch()... }`
  - `ResourceService.hx` → `class ResourceService implements IResourceLoader`
  - `ClipboardService.hx` → `class ClipboardService implements IClipboardService`
- `usecases/` — Конкретные сценарии использования (команды)
  - `LoadProjectUseCase.hx` → `class LoadProjectUseCase { execute(path:FilePath):Promise<Project> }`
  - `OpenResourceUseCase.hx` → `class OpenResourceUseCase { execute(id:ResourceId, type:ViewType):Void }`
  - `SaveLayoutUseCase.hx` → `class SaveLayoutUseCase { execute(config:LayoutConfig):Void }`
  - `SetFullscreenUseCase.hx` → `class SetFullscreenUseCase { execute(value:Bool):Void }`
  - `BuildProjectUseCase.hx` → `class BuildProjectUseCase { execute(options:BuildOptions):Promise<BuildResult> }`
  - `ExportDatabaseUseCase.hx` → `class ExportDatabaseUseCase { execute(format:String, path:FilePath):Void }`
- `events/` — Доменные события (для EventBus)
  - `ProjectLoaded.hx` → `class ProjectLoaded { project:Project, timestamp:Date }`
  - `ResourceOpened.hx` → `class ResourceOpened { resourceId:ResourceId, viewType:ViewType }`
  - `LayoutChanged.hx` → `class LayoutChanged { oldConfig:LayoutConfig, newConfig:LayoutConfig }`
  - `ErrorOccurred.hx` → `class ErrorOccurred { error:Error, context:String }`
- `dto/` — Data Transfer Objects (для передачи между слоями)
  - `WindowBoundsDto.hx` → `typedef WindowBoundsDto = { x:Int, y:Int, width:Int, height:Int }`
  - `MenuItemDto.hx` → `typedef MenuItemDto = { label:String, type:MenuItemType, ?submenu:Array<MenuItemDto>, ?id:String }`
  - `ResourceMetadataDto.hx` → `typedef ResourceMetadataDto = { id:String, type:ResourceType, path:String, size:Int }`

### 🟨 Presentation (`hide/presentation/`) — UI слой (то, что видит пользователь)
- `Ide.hx` → 🔥 **ТОНКИЙ контроллер** (200–300 строк вместо 2000)
  - Инициализирует сервисы через контейнер
  - Обрабатывает пользовательские действия → вызывает Use-Cases
  - Подписывается на события → обновляет UI
  - `НЕ` содержит бизнес-логики!
- `ui/` — Базовые UI-компоненты
  - `View.hx` → `abstract class View<T> { render(), update(), dispose() }`
  - `Element.hx` → Обёртка над DOM (jQuery) — единственное место с прямым доступом к DOM
  - `MenuBuilder.hx` → `class MenuBuilder { fromTemplate(template:Array<MenuItemDto>):Element }`
  - `StatusBar.hx` → `class StatusBar { showMessage(), setError(), setProgress() }`
  - `Dialog.hx` → `class Dialog { showConfirm(), showInput(), showFilePicker() }`
- `views/` — Конкретные панели (наследуют `View<T>`)
  - `ModelView.hx` → `class ModelView extends View<ModelViewState> { ... }`
  - `PrefabView.hx` → `class PrefabView extends View<PrefabViewState> { ... }`
  - `CdbTableView.hx` → `class CdbTableView extends View<CdbTableState> { ... }`
  - `ScriptEditorView.hx` → `class ScriptEditorView extends View<ScriptEditorState> { ... }`
  - `...` (остальные 50+ видов)
- `controllers/` — Обработчики пользовательских действий (опционально)
  - `MenuController.hx` → `class MenuController { onMenuItemClick(id:String):Void }`
  - `KeyboardController.hx` → `class KeyboardController { onKeyPress(key:KeyCombo):Void }`
  - `DragDropController.hx` → `class DragDropController { onDrop(resource:ResourceDto):Void }`
- `styles/` — CSS/темы (если выносите стили отдельно)
  - `Theme.hx` → `enum Theme { Dark; Light; System }`
  - `CssVariables.hx` → `typedef CssVariables = { primaryColor:String, fontSize:Int, ... }`

### 🟥 Infrastructure (`hide/infrastructure/`) — Внешние зависимости (адаптеры)
- `platform/` — Адаптеры под платформы (реализация портов из `domain/services`)
  - `electron/`
    - `ElectronWindowAdapter.hx` → `class ElectronWindowAdapter implements IWindowManager`
    - `ElectronClipboardAdapter.hx` → `class ElectronClipboardAdapter implements IClipboardService`
    - `ElectronFileSystemAdapter.hx` → `class ElectronFileSystemAdapter implements IFileSystem`
    - `ElectronScreenAdapter.hx` → `class ElectronScreenAdapter implements IScreenService`
    - `ElectronShortcutAdapter.hx` → `class ElectronShortcutAdapter implements IShortcutManager`
    - `ElectronIpcBridge.hx` → `class ElectronIpcBridge { send(), on(), invoke() }`
  - `nwjs/` — Адаптеры для NW.js (для плавной миграции)
    - `NwWindowAdapter.hx`, `NwClipboardAdapter.hx`, `...`
  - `web/` — Адаптеры для браузера (для тестов или веб-версии)
    - `BrowserWindowAdapter.hx`, `LocalStorageAdapter.hx`, `...`
- `persistence/` — Реализация репозиториев (сохранение/загрузка)
  - `FileSystemRepository.hx` → `class FileSystemRepository implements IResourceRepository`
  - `LocalStorageRepository.hx` → `class LocalStorageRepository implements ISettingsRepository`
  - `MemoryRepository.hx` → `class MemoryRepository<T>` (для тестов)
- `external/` — Обёртки над сторонними библиотеками
  - `GoldenLayoutAdapter.hx` → `class GoldenLayoutAdapter implements ILayoutEngine`
  - `MonacoEditorAdapter.hx` → `class MonacoEditorAdapter implements ICodeEditor`
  - `HeapsEngineAdapter.hx` → `class HeapsEngineAdapter implements IRenderEngine`
  - `jQueryElementAdapter.hx` → `class jQueryElementAdapter implements IElement`
- `config/` — Загрузка конфигурации из внешних источников
  - `PackageJsonLoader.hx` → `class PackageJsonLoader { load():IdeConfig }`
  - `UserSettingsLoader.hx` → `class UserSettingsLoader { load():UserSettings }`
  - `ProjectConfigParser.hx` → `class ProjectConfigParser { parse(json:String):ProjectConfig }`

### ⚪ Shared (`hide/shared/`) — Общие утилиты (могут использоваться во всех слоях)
- `utils/`
  - `PathUtils.hx` → `static function join(parts:Array<String>):String`
  - `JsonUtils.hx` → `static function safeParse<T>(json:String, default:T):T`
  - `AsyncUtils.hx` → `static function promiseToCallback<T>(p:Promise<T>, cb:T->Void):Void`
- `types/`
  - `Result.hx` → `enum Result<T, E> { Success(T); Failure(E) }`
  - `Option.hx` → `enum Option<T> { Some(T); None }`
  - `NonEmptyArray.hx` → `abstract class NonEmptyArray<T>`
- `extensions/` — Расширения стандартных типов
  - `StringExt.hx` → `using StringExt; "hello".capitalize()`
  - `ArrayExt.hx` → `using ArrayExt; [1,2,3].unique()`
  - `DateExt.hx` → `using DateExt; Date.now().format("YYYY-MM-DD")`

---

### 📦 Корневые файлы и тесты
- `tests/` — Тесты (отдельно от исходников)
  - `unit/` — Юнит-тесты (без DOM, без Electron)
    - `domain/` → `ProjectTest.hx`, `FilePathTest.hx`
    - `application/` → `LoadProjectUseCaseTest.hx`, `MenuServiceTest.hx`
    - `mocks/` → `MockWindowManager.hx`, `MockFileSystem.hx`, `MockEventBus.hx`
  - `integration/` — Интеграционные тесты (с реальными адаптерами)
    - `ElectronIpcTest.hx`, `FileSystemRepositoryTest.hx`
  - `e2e/` — End-to-end тесты (запуск приложения)
    - `IdeStartupTest.hx`, `ProjectLoadTest.hx`
- `build.hxml` → Настройки компиляции Haxe
- `package.json` → Конфиг Electron / NW.js
- `README.md` → Документация по архитектуре проекта