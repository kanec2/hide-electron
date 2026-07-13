// hide/presentation/ui/react/components/ProjectPanel.hx
package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.application.services.ProjectTreeService;
import hide.application.services.ProjectTreeService.TreeNode;
import hide.shared.events.ResourceOpened;
import hide.presentation.ui.react.components.ContextMenu;

typedef ProjectProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

// ✅ ИСПРАВЛЕНО: используем Dynamic вместо Map для совместимости с React
typedef ProjectState = {
    var rootNodes: Array<TreeNode>;
    var searchQuery: String;
    var contextMenu: Null<{x: Float, y: Float, node: TreeNode}>;
    var expandedFolders: Dynamic; // key: relativePath, value: Bool
    var childrenCache: Dynamic;   // key: absolutePath, value: Array<TreeNode>
}

class ProjectPanel extends BaseReactComponent<ProjectProps, ProjectState> {
    private var service: ProjectTreeService;

    public function new() {
        super();
        service = UseService.projectTree();
        state = { 
            rootNodes: [], 
            searchQuery: "",
            contextMenu: null,
            expandedFolders: {},      // Пустой JS-объект
            childrenCache: {}         // Пустой JS-объект
        };
    }

    override function componentDidMount(): Void {
        loadRoot();
    }

    private function loadRoot(): Void {
        service.readDir(null).handle(function(nodes) {
            setState({ 
                rootNodes: nodes, 
                searchQuery: state.searchQuery,
                contextMenu: state.contextMenu,
                expandedFolders: state.expandedFolders,
                childrenCache: state.childrenCache
            });
        });
    }

    // ===== Логика раскрытия папок =====
    private function toggleFolder(node: TreeNode): Void {
        var path = node.relativePath;
        
        // ✅ Читаем состояние из Dynamic через Reflect
        var isExpanded = Reflect.field(state.expandedFolders, path) == true;
        
        // 1. Переключаем состояние раскрытия
        var newExpanded = Reflect.copy(state.expandedFolders);
        Reflect.setField(newExpanded, path, !isExpanded);

        // 2. Если раскрываем впервые и детей нет — загружаем их
        if (!isExpanded && !Reflect.hasField(state.childrenCache, node.path)) {
            // Ставим заглушку (пустой массив), чтобы UI показал "Loading..."
            var newCache = Reflect.copy(state.childrenCache);
            Reflect.setField(newCache, node.path, []); 
            
            setState({
                rootNodes: state.rootNodes,
                searchQuery: state.searchQuery,
                contextMenu: state.contextMenu,
                expandedFolders: newExpanded,
                childrenCache: newCache
            });

            // Асинхронная загрузка по АБСОЛЮТНОМУ пути
            service.readDir(node.path).handle(function(children) {
                var updatedCache = Reflect.copy(newCache);
                Reflect.setField(updatedCache, node.path, children);
                
                trace('📥 [UI] Loaded ${children.length} children for: ${node.name}');
                
                setState({
                    rootNodes: state.rootNodes,
                    searchQuery: state.searchQuery,
                    contextMenu: state.contextMenu,
                    expandedFolders: newExpanded,
                    childrenCache: updatedCache
                });
            });
        } else {
            // Просто обновляем состояние раскрытия
            setState({
                rootNodes: state.rootNodes,
                searchQuery: state.searchQuery,
                contextMenu: state.contextMenu,
                expandedFolders: newExpanded,
                childrenCache: state.childrenCache
            });
        }
    }

    // ===== Поиск =====
    private function handleSearchChange(e: js.html.Event): Void {
        var target = cast(e.target, js.html.InputElement);
        setState({ 
            rootNodes: state.rootNodes, 
            searchQuery: target.value.toLowerCase(),
            contextMenu: state.contextMenu,
            expandedFolders: state.expandedFolders,
            childrenCache: state.childrenCache
        });
    }

    private function clearSearch(): Void {
        setState({ 
            rootNodes: state.rootNodes, 
            searchQuery: "",
            contextMenu: state.contextMenu,
            expandedFolders: state.expandedFolders,
            childrenCache: state.childrenCache
        });
    }

    private function matchesSearch(node: TreeNode, query: String): Bool {
        if (query == "") return true;
        if (node.name.toLowerCase().indexOf(query) != -1) return true;
        return false; 
    }

    private function highlightText(text: String, query: String): ReactElement {
        if (query == "" || text.toLowerCase().indexOf(query) == -1) {
            return jsx('<span>{text}</span>');
        }
        var lowerText = text.toLowerCase();
        var lowerQuery = query.toLowerCase();
        var parts: Array<ReactElement> = [];
        var lastIndex = 0;
        var index = 0;
        while ((index = lowerText.indexOf(lowerQuery, lastIndex)) != -1) {
            if (index > lastIndex) parts.push(jsx('<span key={"t" + parts.length}>{text.substring(lastIndex, index)}</span>'));
            parts.push(jsx('<span key={"h" + parts.length} style={{backgroundColor: "#facc15", color: "#000", borderRadius: "2px", padding: "0 2px", fontWeight: "bold"}}>{text.substring(index, index + query.length)}</span>'));
            lastIndex = index + query.length;
        }
        if (lastIndex < text.length) parts.push(jsx('<span key={"e" + parts.length}>{text.substring(lastIndex)}</span>'));
        return jsx('<span>{parts}</span>');
    }

    // ===== Контекстное меню =====
    private function getContextMenuItems(node: TreeNode): Array<hide.presentation.ui.react.components.ContextMenu.MenuItem> {
        var closeMenu = function() {
            setState({
                rootNodes: state.rootNodes,
                searchQuery: state.searchQuery,
                contextMenu: null,
                expandedFolders: state.expandedFolders,
                childrenCache: state.childrenCache
            });
        };

        var items: Array<hide.presentation.ui.react.components.ContextMenu.MenuItem> = [
            { label: "Open", icon: "📂", action: function() {
                UseService.eventBus().publish(ResourceOpened, new ResourceOpened(node.path));
                closeMenu();
            }}
        ];

        if (node.isDirectory) {
            items.push({ separator: true, label: "sep1", action: function(){} });
            items.push({ label: "Reveal in Explorer", icon: "", action: function() {
                closeMenu();
            }});
        } else {
            items.push({ separator: true, label: "sep1", action: function(){} });
            items.push({ label: "Delete", icon: "🗑️", action: function() {
                if (js.Browser.window.confirm("Delete '" + node.name + "'?")) {
                    trace("TODO: Delete file " + node.path);
                }
                closeMenu();
            }});
        }
        return items;
    }

    private function handleContextMenu(e: js.html.MouseEvent, node: TreeNode): Void {
        e.preventDefault();
        e.stopPropagation();
        var menuWidth = 200;
        var menuHeight = 300;
        var winW = js.Browser.window.innerWidth;
        var winH = js.Browser.window.innerHeight;
        var x = e.clientX;
        var y = e.clientY;
        if (x + menuWidth > winW) x = winW - menuWidth - 10;
        if (y + menuHeight > winH) y = winH - menuHeight - 10;

        setState({
            rootNodes: state.rootNodes,
            searchQuery: state.searchQuery,
            contextMenu: { x: x, y: y, node: node },
            expandedFolders: state.expandedFolders,
            childrenCache: state.childrenCache
        });
    }

    // ===== Рендеринг =====
    override function render(): ReactElement {
        var hasQuery = state.searchQuery.length > 0;
        var clearIcon = hasQuery ? jsx('
            <button onClick={clearSearch} title="Clear search" style={{background: "transparent", border: "none", color: "#888", cursor: "pointer", padding: "2px", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "3px"}} onMouseOver={function(e) untyped e.currentTarget.style.color = "#fff"} onMouseOut={function(e) untyped e.currentTarget.style.color = "#888"}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
        ') : null;

        var ctxMenu = state.contextMenu != null ? jsx('
            <ContextMenu x={state.contextMenu.x} y={state.contextMenu.y} 
                items={getContextMenuItems(state.contextMenu.node)}
                onClose={function() setState({rootNodes: state.rootNodes, searchQuery: state.searchQuery, contextMenu: null, expandedFolders: state.expandedFolders, childrenCache: state.childrenCache})}
            />
        ') : null;

        return jsx('
            <div style={{display: "flex", flexDirection: "column", height: "100%", background: "#383838"}}>
                <div style={{padding: "6px", borderBottom: "1px solid #2a2a2a", display: "flex", alignItems: "center", gap: "4px", background: "#2a2a2a"}}>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#888" strokeWidth="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    <input id="project-search-input" type="text" placeholder="Search Assets..." value={state.searchQuery} onChange={handleSearchChange} style={{width: "100%", padding: "4px 8px", background: "#2a2a2a", border: "1px solid #444", borderRadius: "3px", color: "#d4d4d4", outline: "none", boxSizing: "border-box"}} />
                    {clearIcon}
                </div>
                <div style={{flex: 1, overflowY: "auto", padding: "4px 0"}}>
                    {[for (node in state.rootNodes) renderNode(node, 0)]}
                </div>
                {ctxMenu}
            </div>
        ');
    }

    private function getNodeIcon(node: TreeNode): String {
        if (node.isDirectory) return "";
        return switch (node.extension) {
            case "hx": "🟦";
            case "json", "shadergraph": "📋";
            case "png", "jpg", "jpeg", "webp": "🖼️";
            case "scene", "prefab": "";
            default: "📄";
        };
    }

    private function renderNode(node: TreeNode, depth: Int): ReactElement {
    if (!matchesSearch(node, state.searchQuery)) {
        return jsx('<div key={node.path}></div>'); 
    }

    var paddingLeft = depth * 16 + 8;
    var isExpanded = Reflect.field(state.expandedFolders, node.relativePath) == true;
    
    // ✅ ИСПРАВЛЕНИЕ: Логика выбора иконки теперь едина для всех типов
    var icon = if (node.isDirectory) {
        isExpanded ? "📂" : "📁";
    } else if (StringTools.endsWith(node.name, ".meta")) {
        "⚙️"; // Иконка шестеренки для мета-файлов
    } else {
        switch (node.extension) {
            case "hx": "🟦";
            case "json", "shadergraph": "";
            case "png", "jpg", "jpeg", "webp": "🖼️";
            case "scene", "prefab": "🎬";
            default: "";
        }
    };

    // Стрелочка раскрытия
    var arrow = if (node.isDirectory) {
        jsx('<span style={{width:"16px", textAlign:"center", fontSize:"10px", marginRight:"4px", color:"#aaa", cursor:"pointer"}} onClick={function(_) toggleFolder(node)}>{isExpanded ? "▼" : "▶"}</span>');
    } else {
        jsx('<span style={{width:"16px", display:"inline-block"}}></span>');
    };

    var rowStyle = {
        padding: "3px 8px", paddingLeft: paddingLeft + "px", cursor: "pointer", borderRadius: "3px",
        background: "transparent", display: "flex", alignItems: "center",
        whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis"
    };

    // Получаем детей из кэша
    var childrenList: ReactElement = if (node.isDirectory && isExpanded) {
        var children:Null<Array<TreeNode>> = Reflect.field(state.childrenCache, node.path);
        
        if (children == null) {
            jsx('<div style={{paddingLeft: "16px", color: "#666", fontSize: "11px"}}>Loading...</div>');
        } else {
            jsx('<div>{[for (child in children) renderNode(child, depth + 1)]}</div>');
        }
    } else {
        jsx('<div></div>');
    };

    return jsx('
        <div key={node.path}>
            <div style={rowStyle}
                onClick={function(_) {
                    if (node.isDirectory) {
                        toggleFolder(node);
                    } else {
                        UseService.eventBus().publish(ResourceOpened, new ResourceOpened(node.path));
                    }
                }}
                onContextMenu={function(e:js.html.MouseEvent) handleContextMenu(e, node)}
                onMouseOver={function(e) untyped e.currentTarget.style.background = "#444"}
                onMouseOut={function(e) untyped e.currentTarget.style.background = "transparent"}
            >
                {arrow}
                <span style={{marginRight: "6px"}}>{icon}</span>
                {highlightText(node.name, state.searchQuery)}
            </div>
            
            {childrenList}
        </div>
    ');
}
}