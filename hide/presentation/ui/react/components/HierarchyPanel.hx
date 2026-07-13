package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.presentation.ui.react.components.HierarchyIcon;
import hide.presentation.ui.react.components.ContextMenu;
import hide.shared.events.ObjectSelected;
import hide.engine.domain.entities.SceneObject;

typedef HierarchyProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef HierarchyState = {
    var root: Null<SceneObject>;
    var selectedId: Null<String>;
    var searchQuery: String; // <-- НОВОЕ: строка поиска
    var contextMenu: Null<{x: Float, y: Float, objId: String}>; // <-- НОВОЕ
}

class HierarchyPanel extends BaseReactComponent<HierarchyProps, HierarchyState> {
    public function new() {
        super();
        state = { 
            root: null, 
            selectedId: null,
            searchQuery: "", // <-- Инициализируем пустым
            contextMenu: null 
        };
    }

    override function componentDidMount(): Void {
        var scene = UseService.sceneService();
        var eventBus = UseService.eventBus();

        // 1. Загружаем реальное дерево сцены
        setState({ root: scene.getRoot(), selectedId: null, searchQuery: "",contextMenu:state.contextMenu });

        // 2. Подписываемся на изменения сцены (добавление/удаление объектов)
        subscribe(eventBus, hide.shared.events.ObjectChanged, function(_) {
            setState({ root: scene.getRoot(), selectedId: state.selectedId, searchQuery: state.searchQuery,contextMenu:state.contextMenu });
        });

        // 3. Подписываемся на внешний выбор (например, кликом в 3D-вью)
        subscribe(eventBus, ObjectSelected, function(e:ObjectSelected) {
            trace('🖥️ [Hierarchy] Received ObjectSelected: ${e.objectId}');
            setState({ root: state.root, selectedId: e.objectId, searchQuery: state.searchQuery,contextMenu:state.contextMenu });
        });
    }

    // ===== Обработчик изменения поиска =====
    private function handleSearchChange(e: js.html.Event): Void {
        var target = cast(e.target, js.html.InputElement);
        setState({ 
            root: state.root, 
            selectedId: state.selectedId, 
            searchQuery: target.value.toLowerCase() ,
            contextMenu:state.contextMenu
        });
    }

    // ✅ НОВОЕ: Очистка поиска
    private function clearSearch(): Void {
        setState({ 
            root: state.root, 
            selectedId: state.selectedId, 
            searchQuery: "",
            contextMenu:state.contextMenu
        });
        
        // Опционально: можно сразу вернуть фокус в инпут
        var input = js.Browser.document.getElementById("hierarchy-search-input");
        if (input != null) {
            untyped input.focus();
        }
    }

    // ===== Проверка на соответствие запросу =====
    private function matchesSearch(obj: SceneObject, query: String): Bool {
        if (query == "") return true;
        
        // Проверяем имя объекта
        if (obj.name.toLowerCase().indexOf(query) != -1) return true;
        
        // Рекурсивно проверяем детей (чтобы родитель оставался видимым, если найден ребенок)
        for (child in obj.children) {
            if (matchesSearch(child, query)) return true;
        }
        
        return false;
    }

    private function getObjectType(obj: SceneObject): ObjectType {
        // Логика определения типа. Можно расширять под ваши нужды.
        if (obj.name.indexOf("Camera") != -1) return Camera;
        if (obj.name.indexOf("Light") != -1) return Light;
        if (obj.name == "Player") return Player;
        
        // Проверяем наличие компонентов
        /*for (c in obj.components) {
            if (Std.isOfType(c, MeshRenderer)) return Mesh;
        }*/
        
        return Default;
    }
    override function render(): ReactElement {
        if (state.root == null) {
            return jsx('<div style={{padding:"10px",color:"#888"}}>No scene loaded</div>');
        }

        // Проверяем, есть ли что очищать
        var hasQuery = state.searchQuery.length > 0;
        var clearIcon = hasQuery ? jsx('
            <button 
                onClick={clearSearch}
                title="Clear search"
                style={{
                    background: "transparent",
                    border: "none",
                    color: "#888",
                    cursor: "pointer",
                    padding: "2px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    borderRadius: "3px"
                }}
                onMouseOver={function(e) untyped e.currentTarget.style.color = "#fff"}
                onMouseOut={function(e) untyped e.currentTarget.style.color = "#888"}
            >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        ') : null;

        var ctxMenu = state.contextMenu != null ? jsx('
            <ContextMenu 
                x={state.contextMenu.x} 
                y={state.contextMenu.y} 
                items={getHierarchyContextMenu(state.contextMenu.objId)}
                onClose={function() setState({root: state.root, selectedId: state.selectedId, searchQuery: state.searchQuery, contextMenu: null})}
            />
        ') : null;
        return jsx('
            <div style={{display: "flex", flexDirection: "column", height: "100%", background: "#383838"}}>
                <div style={{padding: "6px", 
                    borderBottom: "1px solid #2a2a2a",
                    display: "flex",
                    alignItems: "center",
                    gap: "4px",
                    background: "#2a2a2a"
                }}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#888" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                    <input 
                        type="text" 
                        placeholder="Search objects..." 
                        value={state.searchQuery}
                        onChange={handleSearchChange}
                        style={{
                            width: "100%", 
                            padding: "4px 8px", 
                            background: "#2a2a2a", 
                            border: "1px solid #444", 
                            borderRadius: "3px", 
                            color: "#d4d4d4",
                            outline: "none",
                            boxSizing: "border-box"
                        }}
                    />
                    {clearIcon}
                </div>

                <div style={{flex: 1, overflowY: "auto", padding: "4px 0"}}>
                    {renderObject(state.root, 0)}
                </div>
                {ctxMenu}
            </div>
        ');
    }

    // Метод для генерации пунктов меню
    private function getHierarchyContextMenu(objId: String): Array<hide.presentation.ui.react.components.ContextMenu.MenuItem> {
        var scene = UseService.sceneService();
        var obj = scene.getObject(objId);
        if (obj == null) return [];

        var isRoot = obj.parent == null;
        var closeMenu = function() {
            setState({
                root: state.root,
                selectedId: state.selectedId,
                searchQuery: state.searchQuery,
                contextMenu: null // ✅ Закрываем меню после действия
            });
        };
        return [
            {
                label: "Rename",
                icon: "✏️",
                action: function() {
                    var newName = js.Browser.window.prompt("Enter new name:", obj.name);
                    if (newName != null && newName.length > 0) {
                        scene.rename(objId, newName);
                    }
                    closeMenu();
                }
            },
            {
                label: "Duplicate",
                icon: "📋",
                action: function() {
                    // TODO: Реализовать дублирование через сервис сцены
                    trace("Duplicate requested for: " + obj.name);
                    closeMenu();
                }
            },
            { separator: true, label: "sep1", action: function(){} },
            {
                label: "Create Empty Child",
                icon: "➕",
                action: function() {
                    // TODO: Создать пустой объект и добавить как ребенка
                    trace("Create child for: " + obj.name);
                    closeMenu();
                }
            },
            { separator: true, label: "sep2", action: function(){} },
            {
                label: "Delete",
                icon: "🗑️",
                disabled: isRoot, // Корневой объект нельзя удалить
                action: function() {
                    if (js.Browser.window.confirm("Delete '" + obj.name + "'?")) {
                        // TODO: Удаление объекта
                        trace("Delete requested for: " + obj.name);
                        closeMenu();
                    }
                }
            }
        ];
    }

    // Обработчик правого клика на строке объекта
    // Добавьте этот пропс в div строки объекта в renderObject():
    // onContextMenu={function(e) handleContextMenu(e, obj.id)}
    private function handleContextMenu(e: js.html.MouseEvent, objId: String): Void {
        e.preventDefault();
        e.stopPropagation();
        // ✅ ЗАЩИТА ОТ ВЫХОДА ЗА ГРАНИЦЫ ЭКРАНА
        var menuWidth = 200; // Примерная ширина меню
        var menuHeight = 250; // Примерная высота
        var winW = js.Browser.window.innerWidth;
        var winH = js.Browser.window.innerHeight;
        
        var x = e.clientX;
        var y = e.clientY;
        
        // Если меню не помещается справа — показываем слева от курсора
        if (x + menuWidth > winW) {
            x = winW - menuWidth - 10;
        }
        
        // Если меню не помещается снизу — показываем выше курсора
        if (y + menuHeight > winH) {
            y = winH - menuHeight - 10;
        }
        setState({
            root: state.root,
            selectedId: state.selectedId,
            searchQuery: state.searchQuery,
            contextMenu: { x: x, y: y, objId: objId }
        });
    }
    /**
     * Разбивает текст на массив ReactElement, подсвечивая совпадения желтым цветом.
     */
    private function highlightText(text: String, query: String): ReactElement {
        if (query == "" || text.toLowerCase().indexOf(query) == -1) {
            return jsx('<span>{text}</span>');
        }

        var lowerText = text.toLowerCase();
        var lowerQuery = query.toLowerCase();
        var parts: Array<ReactElement> = [];
        var lastIndex = 0;
        var index = 0;

        // Находим все вхождения (для простоты берем первое, так как indexOf не глобальный)
        // Для множественных совпадений можно использовать EReg с флагом 'g'
        while ((index = lowerText.indexOf(lowerQuery, lastIndex)) != -1) {
            // Добавляем текст ДО совпадения
            if (index > lastIndex) {
                parts.push(jsx('<span key={"t" + parts.length}>{text.substring(lastIndex, index)}</span>'));
            }
            
            // Добавляем ПОДСВЕЧЕННОЕ совпадение
            parts.push(jsx('
                <span 
                    key={"h" + parts.length} 
                    style={{
                        backgroundColor: "#facc15", 
                        color: "#000", 
                        borderRadius: "2px", 
                        padding: "0 2px",
                        fontWeight: "bold"
                    }}
                >
                    {text.substring(index, index + query.length)}
                </span>
            '));
            
            lastIndex = index + query.length;
        }

        // Добавляем остаток текста
        if (lastIndex < text.length) {
            parts.push(jsx('<span key={"e" + parts.length}>{text.substring(lastIndex)}</span>'));
        }

        return jsx('<span>{parts}</span>');
    }
    
    private function renderObject(obj: SceneObject, depth: Int): ReactElement {
        // ✅ Если идет поиск и этот узел (включая всех его потомков) не подходит — скрываем его полностью
        if (!matchesSearch(obj, state.searchQuery)) {
            return jsx('<div key={obj.id}></div>'); 
        }

        var isSelected = state.selectedId == obj.id;
        var hasChildren = obj.children != null && obj.children.length > 0;
        var paddingLeft = depth * 16;

        var rowStyle = {
            padding: "3px 8px",
            paddingLeft: (paddingLeft + 8) + "px",
            cursor: "pointer",
            borderRadius: "3px",
            background: isSelected ? "#2d5c8a" : "transparent",
            display: "flex",
            alignItems: "center"
        };

        // Определяем тип для иконки (упрощенная логика, можно расширить)
        var iconType = ObjectType.Default;
        if (obj.name.indexOf("Camera") != -1) iconType = Camera;
        else if (obj.name.indexOf("Light") != -1) iconType = Light;
        else if (obj.name == "Player") iconType = Player;
        else if (obj.components.length > 0) iconType = Mesh;

        // Рендерим детей только если они есть и проходят фильтр
        var childrenList: ReactElement = if (hasChildren) {
            jsx('<div>{[for (child in obj.children) renderObject(child, depth + 1)]}</div>');
        } else {
            jsx('<div></div>');
        };

        return jsx('
             <div key={obj.id}>
                 <div
                    style={rowStyle}
                    onClick={function(_) handleSelect(obj.id)}
                    onContextMenu={function(e:js.html.MouseEvent) handleContextMenu(e, obj.id)}
                    >
                    

                    <span style={{width: "16px", textAlign: "center", fontSize: "10px", marginRight: "4px", color: "#888"}}>
                        {hasChildren ? "▼" : " "}
                    </span>
                    

                    <HierarchyIcon type={iconType} />

                    {highlightText(obj.name, state.searchQuery)}
                 </div>
                {childrenList}
             </div>
        ');
    }

    

    private function handleSelect(id: String): Void {
        // ✅ ЧИСТО: просто вызываем метод движка.
        // Движок сам опубликует ObjectSelected через IEngineEventBus →
        // SceneEditorService → IDE EventBus → наша подписка выше обновит UI.
        trace('🎯 [Hierarchy] Selecting object: $id');
        UseService.sceneService().select(id);
    }
}