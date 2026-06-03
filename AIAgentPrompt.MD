🎯 PROJECT REFACTORING CONTEXT & AI AGENT INSTRUCTIONS
📌 Project Overview
Name: HeapsIO/hide (Game/Content Editor IDE)
Language: Haxe 4.x → JavaScript/HTML/CSS
Current Platform: NW.js (nw.* API calls scattered throughout codebase)
Target Platform: Electron (Renderer + Main process, IPC-based communication)
Key Dependencies: Heaps (h3d, hxd), GoldenLayout, Monaco Editor, jQuery, sys.*, js.*
🔴 Current State (Pain Points)
Monolithic Ide.hx (~2000+ lines) acting as God Object
Direct platform calls (nw.Window.get(), nw.App.dataPath, nw.Clipboard, nw.Screen, new nw.Menu()) tightly mixed with business logic and UI rendering
Impossible to unit-test without launching the full native app
Hard to migrate from NW.js to Electron incrementally
hide/ui/Menu.hx returns native nw.Menu objects (unserializable, blocks IPC to main process)
No clear boundaries between UI, business rules, and platform adapters
🟢 Target Architecture: Layered (Clean Architecture)
Follow the Dependency Rule: Dependencies point inward. Outer layers know about inner layers. Inner layers know NOTHING about outer layers.
🗂️ Target Folder Structure
hide_js/hide/
├── domain/                 # 🔷 Pure Haxe. 0 external deps.
│   ├── entities/           # Business objects (Project, Resource, Database, UserSettings)
│   ├── valueobjects/       # Immutable types (FilePath, ResourceId, ScreenBounds)
│   ├── enums/              # Enums (ResourceType, WindowEvent, MenuItemType)
│   ├── services/           # PORTS/INTERFACES (IWindowManager, IFileSystem, IEventBus, ILayoutEngine)
│   └── exceptions/         # Domain-specific errors (ProjectLoadError, ResourceNotFound)
├── application/            # 🟩 Use-Cases & App Services
│   ├── usecases/           # Single-responsibility commands (LoadProject, SetFullscreen, ExportDB)
│   ├── services/           # Orchestrators (WindowService, MenuService, LayoutService)
│   ├── events/             # Domain events (ProjectLoaded, ErrorOccurred, LayoutChanged)
│   └── dto/                # Data Transfer Objects for cross-layer communication
├── infrastructure/         # 🟥 Platform Adapters & External Libs
│   ├── platform/           # Electron/NWJS/Browser implementations of domain ports
│   ├── external/           # Adapters for GoldenLayout, Monaco, Heaps, jQuery
│   ├── persistence/        # File/LocalStorage repositories
│   └── config/             # Package.json, settings loaders
├── presentation/           # 🟨 UI & Thin Controllers
│   ├── Ide.hx              # Thin controller (init DI, route UI events to use-cases, subscribe to events)
│   ├── ui/                 # Base components (View<T>, Element wrapper, StatusBar, Dialog)
│   ├── views/              # Concrete panels (ModelView, CdbTableView, ScriptEditorView)
│   └── controllers/        # Input handlers (Menu, Keyboard, DragDrop)
└── shared/                 # ⚪ Cross-cutting utilities (Result<T,E>, PathUtils, ArrayExt, Option<T>)
📐 Core Architectural Rules
Domain must compile with zero import js.*, import electron.*, or import nw.*. Pure business logic only.
Application depends ONLY on Domain interfaces & shared/.
Infrastructure implements Domain ports. Contains ALL js.Node.*, electron.*, nw.* calls.
Presentation depends on Application. Contains ONLY UI rendering & user input routing.
Ide.hx becomes a thin controller (<300 lines). No business logic. Only: init DI container, bind UI events to Use-Cases, subscribe to events, update UI.
Use Result<T, E> or Option<T> for cross-boundary error handling. No untyped exceptions crossing layers.
All platform calls go through ports/interfaces. Never return platform-specific objects (nw.Menu, electron.BrowserWindow) across layer boundaries. Use typedef/DTOs instead.
🔄 Migration Strategy (Iterative Vertical Slices)
Do NOT rewrite everything at once. Migrate feature-by-feature, compile & test at each step:
✅ Window Management (IWindowManager → WindowService → ElectronWindowAdapter)
⬜ File System & Project Loading (IFileSystem → LoadProjectUseCase → ElectronFileSystemAdapter)
⬜ Menu & Clipboard (IMenuService → HTML→Template parser → IPC → ElectronClipboardAdapter)
⬜ Layout Engine (ILayoutEngine → GoldenLayoutAdapter)
⬜ Resources & Shaders (IResourceLoader → Heaps integration)
⬜ Final Cleanup: Remove old nw.* fallbacks, enforce strict layer boundaries, add unit tests.
🤖 AI AGENT INSTRUCTIONS (How You Must Help)
When I request refactoring or new code:
Respect Layers Explicitly: State which layer each file belongs to. Never mix platform code in Domain/Application.
Provide Exact File Paths: Use hide_js/hide/domain/services/IWindowManager.hx format.
Show Minimal Changes First: If modifying existing code, show only the diff or exact replacement block. Do not dump entire files unless requested.
Haxe-Specific Syntax: Use Haxe 4.x features: enum, typedef, @:op, Result<T,E>, strict typing, abstract for value objects. Avoid JS-style dynamic patterns.
Compilation-Safe: All code must compile with standard Haxe compiler. If external dependencies are needed, mark them with // @:requires lib:xyz or conditional compilation #if electron.
Test-Ready Design: Prefer dependency injection over global singletons. Make services mockable. Provide example unit test structure when relevant.
Ask Before Over-Engineering: If a feature can be done simply, propose the simple version first. Only add abstractions if strictly necessary for the architecture.
Output Format (STRICT):
📁 FILE: hide/path/to/file.hx
🏷️ LAYER: Domain / Application / Infrastructure / Presentation
💡 PURPOSE: [1-sentence explanation]
📝 CODE: [Haxe code block]
⚠️ NOTES: [Compilation tips, DI registration, migration warnings]
🚫 STRICT CONSTRAINTS
NO nw.* calls in domain/ or application/.
NO js.Browser.window or document in domain/.
NO business logic in Ide.hx (only routing & UI updates).
NO global singletons except for DI container bootstrap.
ALWAYS use interface for cross-layer dependencies.
NEVER return platform-specific objects across layer boundaries. Use DTOs/typedefs.
KEEP existing functionality working during migration. No breaking changes until a slice is fully tested.
✅ Expected Workflow
I request a slice (e.g., "Extract IFileSystem and LoadProjectUseCase").
You provide: Domain interface → Application Use-Case → Infrastructure adapter → Presentation wiring (minimal Ide.hx changes).
I compile & test. Report errors or ask for adjustments.
You fix & we proceed to the next slice.
After 3-4 slices, we extract Ide.hx fully into presentation/Ide.hx + ServiceContainer.



💡 Как использовать этот промпт
Скопируйте весь текст выше.
Вставьте в начало нового чата с любым AI-ассистентом.
Добавьте сверху короткую команду:
Прочитай контекст выше. Подтверди, что понял правила архитектуры и формат вывода. 
Жду моего запроса по следующей вертикальной нарезке.
AI запомнит структуру, ограничения и будет отвечать строго по шаблону 📁 FILE / 🏷️ LAYER / 💡 PURPOSE / 📝 CODE / ⚠️ NOTES.