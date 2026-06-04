# 📁 `hide/domain/entities/Project.hx`

---

## ✅ Роль в архитектуре

| Параметр | Значение |
|----------|----------|
| **Слой** | `domain.entities` |
| **Уровень** | Сущность (Entity) — ядро бизнес-логики |

---

## ✅ Что делает

`Project` — это объект домена, представляющий:

- 📁 **Проект** — файловая структура, идентификатор, имя
- 📦 **Коллекцию ресурсов** — файлы, папки, конфиги
- 📊 **Состояние изменений** — флаг `_isDirty` (нужно ли сохранить)

### 🔧 Основные операции

| Метод | Описание |
|-------|----------|
| `new(id, name, rootPath)` | Конструктор с валидацией пути |
| `addResource(resource)` | Добавить ресурс (файл/папку) |
| `getResource(id)` | Получить ресурс по ID |
| `getResourcesByType(type)` | Получить ресурсы по типу (например, только файлы) |
| `markSaved()` | Сбросить флаг `_isDirty` после сохранения |

---

## ✅ От чего зависит

| Зависимость | Тип | Роль |
|-------------|-----|------|
| `hide.domain.valueobjects.FilePath` | valueobject | Типобезопасный путь (всегда валидный) |
| `hide.domain.enums.ResourceType` | enum | Тип ресурса (`File` / `Folder` / `Config`) |
| `hide.domain.entities.Resource` | entity | Сущность ресурса (файл, папка) |

> ⚠️ **Критично:** `Project` **не должен** зависеть от:
> - `js.html.Element` (UI)
> - `golden.Layout` (layout engine)
> - `IFileDialog` (платформа)

---

## ✅ Как его правильно использовать

### 1️⃣ Создание проекта (Use-Case)

```haxe
// hide/application/commands/LoadProjectUseCase.hx

class LoadProjectUseCase {
    public function execute(filePath: FilePath): Result {
        var project = new Project(
            id = UUID.generate(),
            name = filePath.basename(),
            rootPath = filePath
        );

        // Загрузить ресурсы (например, из JSON)
        for (resource in loadResources(filePath)) {
            project.addResource(resource);
        }

        // Опубликовать событие
        eventBus.publish(new ProjectLoaded(project));
        return Success(project);
    }
}
```

# 📁 `hide/domain/enums/WindowEvent.hx`

---

## ✅ Роль в архитектуре

| Параметр | Значение |
|----------|----------|
| **Слой** | `domain.enums` |
| **Тип** | Enum (перечисление) — ограничивает допустимые значения |

---

## ✅ Что делает

`WindowEvent` — это перечисление событий окна, которое:

- 🎯 **Заменяет строковые литералы** (`"focus"`, `"blur"`) → типобезопасность
- 🛡️ **Гарантирует**, что в `WindowService` можно передать только действительно существующие события
- 🧩 **Используется** в `WindowService`, `Window`, `LayoutEngine`

### Пример использования

```haxe
// hide/application/services/WindowService.hx

class WindowService {
    public function on(event: WindowEvent, callback: Void->Void): Void {
        switch event {
            case Focus: // ...
            case Blur: // ...
            case Resize: // ...
            // ... другие случаи
        }
    }
}
```

# 📁 `hide/domain/services/IFileSystem.hx`

---

## ✅ Роль в архитектуре

| Параметр | Значение |
|----------|----------|
| **Слой** | `domain.services` |
| **Тип** | Порт (Port) — доменный интерфейс для взаимодействия с внешним миром |

---

## ✅ Что делает

`IFileSystem` — это абстракция файловой системы, которая:

- 📁 **Определяет доменные операции** — чтение, запись, проверка существования
- 🛡️ **Изолирует домен от платформы** — Electron, NW.js, Node.js, Browser
- 📦 **Используется** в `LoadProjectUseCase`, `SaveProjectUseCase`, `OpenFileUseCase`

### 🔧 Основные методы

| Метод | Описание |
|-------|----------|
| `exists(path)` | Проверка существования пути |
| `readText(path)` | Чтение текстового файла |
| `writeText(path, content)` | Запись текста в файл |
| `listFiles(path, ?recursive)` | Рекурсивный список файлов |
| `getAppDataPath()` | Путь к директории данных приложения |

---

## ✅ От чего зависит

| Зависимость | Тип | Роль |
|-------------|-----|------|
| `FilePath` | valueobject | Типобезопасный путь (всегда валидный) |
| `FileNotFoundError` | exception | Исключение при отсутствии файла |
| `IOError` | exception | Исключение при ошибке ввода-вывода |

> ⚠️ **Критично:** `IFileSystem` **не должен** зависеть от:
> - `js.html.File` (браузер)
> - `nw.Window` (NW.js)
> - `electron.remote` (Electron)

---

## ✅ Как его правильно использовать

### 1️⃣ Use-Case: `LoadProjectUseCase`

```haxe
// hide/application/commands/LoadProjectUseCase.hx

class LoadProjectUseCase {
    private var fileSystem: IFileSystem;

    public function new(fileSystem: IFileSystem) {
        this.fileSystem = fileSystem;
    }

    public function execute(filePath: FilePath): Result {
        if (!fileSystem.exists(filePath)) {
            return Error(new FileNotFoundError(filePath.toString()));
        }

        var json = fileSystem.readText(filePath);
        var projectData = parseJson(json);
        
        // Создать проект
        return Success(new Project(...));
    }
}
```