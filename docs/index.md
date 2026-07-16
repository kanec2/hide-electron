# Документация HIDE on Electron

## 🏗️ Архитектура
- [Обзор архитектуры](architecture/overview.md) — Слои, процессы и принципы
- [IPC Bridge](architecture/ipc-bridge.md) — Взаимодействие Main/Renderer

## 🔄 Data Flow Diagrams
### Основные сценарии
| Файл | Описание |
| :--- | :--- |
| [initial-load.md](flows/initial-load.md) | Инициализация дерева проекта |
| [lazy-load.md](flows/lazy-load.md) | Ленивая загрузка папок (onToggle) |
| [rename-operation.md](flows/rename-operation.md) | Переименование + AssetBrowser sync |
| [create-file-folder.md](flows/create-file-folder.md) | Создание файлов и папок |
| [delete-operation.md](flows/delete-operation.md) | Удаление с очисткой метаданных |
| [drag-and-drop.md](flows/drag-and-drop.md) | Перемещение между директориями |
| [external-changes.md](flows/external-changes.md) | Реакция на изменения извне |

### Системные процессы
| Файл | Описание |
| :--- | :--- |
| [lsp-autocomplete.md](flows/lsp-autocomplete.md) | LSP: автодополнение через JSON-RPC |
| [shader-preview.md](flows/shader-preview.md) | Рендеринг шейдеров (LiteGraph → Heaps) |
| [project-save-load.md](flows/project-save-load.md) | Сохранение/загрузка .hideproj |

## 📚 Справочники
- [Типы данных](reference/types.md) — ArboristNode, HandlerArgs и др.
- [Ограничения и ADR](reference/known-limitations.md) — Known issues и архитектурные решения