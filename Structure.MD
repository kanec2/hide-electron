| Компонент | Слой | Пакет | Ответственность | Примеры |
|---|---|---|---|---|
| `Project`, `Resource` | 🔷 Domain | `domain/entities/` | Бизнес-сущности, правила валидации | `Project.addResource()`, `Resource.type` |
| `FilePath`, `ResourceId` | 🔷 Domain | `domain/valueobjects/` | Типобезопасные значения | `FilePath.validate()`, `ResourceId.toString()` |
| `ResourceType`, `WindowEvent` | 🔷 Domain | `domain/enums/` | Типобезопасные перечисления | `enum ResourceType { Texture, Model }` |
| `IFileSystem`, `IWindowManager` | 🔷 Domain | `domain/services/` | Интерфейсы (порты) для внешних зависимостей | `interface IFileSystem { readText(): String }` |
| `LoadProjectUseCase` | 🟩 Application | `application/usecases/` | Конкретный сценарий использования | `execute(path): Promise<Result<Project, Error>>` |
| `WindowService`, `MenuService` | 🟩 Application | `application/services/` | Оркестрация бизнес-логики | `WindowService.resizeBy()` → делегирование в порт |
| `ProjectLoaded`, `ErrorOccurred` | 🟩 Application | `application/events/` | Доменные события для EventBus | `class ProjectLoaded { project: Project }` |
| `MenuItemDto`, `WindowBoundsDto` | 🟩 Application | `application/dto/` | Объекты для передачи данных между слоями | `typedef MenuItemDto = { label: String, ?submenu: Array<...> }` |
| `Ide.hx` | 🟨 Presentation | `presentation/` | Тонкий контроллер: инициализация, обработка UI-событий | `onMenuOpenProject()` → вызов Use-Case |
| `View<T>`, `Element` | 🟨 Presentation | `presentation/ui/` | Базовые UI-компоненты | `abstract class View<T> { render(), update() }` |
| `ModelView`, `CdbTableView` | 🟨 Presentation | `presentation/views/` | Конкретные панели интерфейса | `class ModelView extends View<ModelState>` |
| `MenuController` | 🟨 Presentation | `presentation/controllers/` | Обработчики пользовательских действий | `onMenuItemClick(id)` → маппинг на Use-Case |
| `ElectronWindowAdapter` | 🟥 Infrastructure | `infrastructure/platform/electron/` | Реализация `IWindowManager` для Electron | `resizeBy()` → `ipc.send("win:resizeBy")` |
| `ElectronFileSystemAdapter` | 🟥 Infrastructure | `infrastructure/platform/electron/` | Реализация `IFileSystem` для Electron | `readText()` → `fs.readFileSync()` |
| `GoldenLayoutAdapter` | 🟥 Infrastructure | `infrastructure/external/` | Адаптер сторонней библиотеки | `implements ILayoutEngine` |
| `Result<T,E>`, `Option<T>` | ⚪ Shared | `shared/types/` | Утилитарные типы для всех слоёв | `enum Result { Success(T), Failure(E) }` |
| `PathUtils`, `JsonUtils` | ⚪ Shared | `shared/utils/` | Общие утилиты | `PathUtils.join(parts)`, `JsonUtils.safeParse()` |