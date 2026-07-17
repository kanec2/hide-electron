// hide/presentation/ui/react/components/ProjectPanel.hx
package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import react.ReactRef; // ✅ Добавь импорт
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.application.services.ProjectTreeService;
import hide.infrastructure.external.ProjectTreeAdapter;
import hide.infrastructure.external.arborist.*;
import hide.shared.events.ResourceOpened;
import hide.domain.services.IFileSystem;       // ✅ Импортируем интерфейс
import hide.domain.valueobjects.FilePath;      // ✅ Импортируем Value Object

typedef ProjectProps = {
    var initialState: Dynamic;
    var onUnmount: Void->Void;
}

typedef ProjectState = {
    var treeData: Array<ArboristNode>;
    var isLoading: Bool;
    var selectedId: Null<String>; // ✅ Храним ID выделения
    var contextMenu: Null<{x: Float, y: Float, node: Dynamic}>;
}

class ProjectPanel extends BaseReactComponent<ProjectProps, ProjectState> {
    private var service: ProjectTreeService;
    private var fs: IFileSystem;
    private var treeRef: ReactRef<Dynamic>; // ✅ Ref для доступа к API дерева
    public function new() {
        super();
        service = UseService.projectTree();
        fs = UseService.fileSystem();
        treeRef = untyped React.createRef(); // ✅ Создаем ref
        state = { 
            treeData: [], 
            isLoading: true,
            selectedId: null,
            contextMenu: null
        };
    }

    override function componentDidMount(): Void {
        loadRoot();
    }

    private function loadRoot(): Void {
        setState({ treeData: [], isLoading: true, selectedId: null, contextMenu: state.contextMenu });
        service.readDir(null).handle(function(nodes) {
            var arboristNodes = ProjectTreeAdapter.toArboristNodes(nodes);
            setState({ treeData: arboristNodes, isLoading: false, selectedId: null, contextMenu: state.contextMenu });
        });
    }
    private function handleContextMenu(e: js.html.MouseEvent, node: Dynamic): Void {
        e.preventDefault();
        e.stopPropagation();
        
        setState({
            treeData: state.treeData,
            isLoading: state.isLoading,
            selectedId: state.selectedId,
            contextMenu: { x: e.clientX, y: e.clientY, node: node }
        });
    }
    private function closeContextMenu(): Void {
        setState({
            treeData: state.treeData,
            isLoading: state.isLoading,
            selectedId: state.selectedId,
            contextMenu: null
        });
    }
    // Получаем пункты меню:
    private function getContextMenuItems(node: Dynamic): Array<hide.presentation.ui.react.components.ContextMenu.MenuItem> {
        var items: Array<hide.presentation.ui.react.components.ContextMenu.MenuItem> = [];
        
        if (node == null) {
            // Меню для пустой области (корня)
            items.push({ 
                label: "New Folder", 
                icon: "📁", 
                action: function() { 
                    trace("New Folder in root");
                    // TODO: handleCreate("", 0, "folder");
                    closeContextMenu();
                } 
            });
            items.push({ 
                label: "New File", 
                icon: "📄", 
                action: function() { 
                    trace("New File in root");
                    closeContextMenu();
                } 
            });
        } else {
            var nodeName = untyped node.data.name;
            var isFolder = untyped !node.data.isLeaf;
            
            items.push({ 
                label: "Open", 
                icon: "📂", 
                action: function() { 
                    trace("Open: $nodeName");
                    closeContextMenu();
                } 
            });
            
            items.push({ separator: true, label: "sep1", action: function(){} });
            
            items.push({ 
                label: "New Folder", 
                icon: "📁", 
                action: function() { 
                    trace("New Folder in $nodeName");
                    // TODO: handleCreate(node.id, 0, "folder");
                    closeContextMenu();
                } 
            });
            
            items.push({ 
                label: "Rename", 
                icon: "✏️", 
                action: function() { 
                    trace("Rename: $nodeName");
                    untyped node.edit();
                    closeContextMenu();
                } 
            });
            
            items.push({ 
                label: "Delete", 
                icon: "🗑️", 
                action: function() { 
                    trace("Delete: $nodeName");
                    handleDelete(node);
                    closeContextMenu();
                } 
            });
        }
        
        return items;
    }
    // ===== РЕКУРСИВНОЕ ОБНОВЛЕНИЕ ДЕРЕВА =====
    // Создает новую копию дерева с измененным узлом (иммутабельность для React)
    private function updateNodeInTree(nodes: Array<ArboristNode>, id: String, changes: Dynamic): Array<ArboristNode> {
        return [for (node in nodes) {
            if (node.id == id) {
                // Применяем изменения к найденному узлу
                untyped Object.assign({}, node, changes);
            } else if (node.children != null) {
                // Рекурсивно идем вглубь
                var newNode = untyped Object.assign({}, node);
                newNode.children = updateNodeInTree(node.children, id, changes);
                newNode;
            } else {
                node;
            }
        }];
    }
    // ===== ПОИСК УЗЛА ПО ID =====
    private function findNodeById(nodes: Array<ArboristNode>, id: String): Null<ArboristNode> {
        for (node in nodes) {
            if (node.id == id) return node;
            if (node.children != null) {
                var found = findNodeById(node.children, id);
                if (found != null) return found;
            }
        }
        return null;
    }
    // ===== ЛОГИКА LAZY LOAD (onToggle) =====
    private function handleToggle(id: String): Void {
        var node = findNodeById(state.treeData, id);
        if (node == null) return;

        // Если дети уже загружены, Arborist сам справится с открытием/закрытием
        if (node.isLoaded == true) return;

        // 1. Включаем индикатор загрузки
        var loadingData = updateNodeInTree(state.treeData, id, { isLoading: true });
        setState({
            treeData: loadingData,
            isLoading: state.isLoading,
            selectedId: state.selectedId, 
            contextMenu: state.contextMenu 
        });

        // 2. Запрашиваем детей у бэкенда
        service.readDir(node.path).handle(function(children) {
            var arboristChildren = ProjectTreeAdapter.toArboristNodes(children);
            
            // 3. Обновляем дерево: подставляем детей, выключаем лоадер, помечаем как загруженное
            var finalData = updateNodeInTree(state.treeData, id, {
                children: arboristChildren,
                isLoading: false,
                isLoaded: true
            });

            setState({
                treeData: finalData,
                isLoading: state.isLoading,
                selectedId: state.selectedId, 
                contextMenu: state.contextMenu 
            });

            // 4. Хак: Принудительно открываем узел через API после обновления стейта
            // Это нужно, потому что обновление стейта асинхронно, и Arborist мог не успеть открыть папку
            js.Browser.window.setTimeout(function() {
                if (treeRef.current != null) {
                    untyped treeRef.current.open(id);
                }
            }, 50);
        });
    }
    // ===== Обработчики событий Arborist =====

    private function handleRename(args: Dynamic): Void {
        var newName: String = untyped args.name;
        var data = untyped args.node.data;
        if (data == null) return;
        
        var oldPathStr: String = untyped data.path;
        var newPathStr = ProjectPanel.replaceNameInPath(oldPathStr, newName);
        
        try {
            // ✅ Чистый вызов доменного сервиса!
            fs.rename(new FilePath(oldPathStr), new FilePath(newPathStr));
            trace('✅ Renamed successfully');
            // ✅ НОВОЕ: Инвалидируем кэш Asset Browser
            var assetBrowser = UseService.assetBrowser();
            if (assetBrowser != null) {
                assetBrowser.invalidateCache();
            }
            refreshParentDirectory(oldPathStr);
        } catch (e: Dynamic) {
            trace('❌ Failed to rename: $e');
            js.Browser.window.alert('Failed to rename: $e');
            // Откат UI в случае ошибки
            invalidateChildrenCache(ProjectPanel.getParentPath(oldPathStr));
        }
    }

    private function handleDelete(args: Dynamic): Void {
        var ids: Array<String> = untyped args.ids;
        var nodes: Array<Dynamic> = untyped args.nodes;  // ← Массив NodeApi
        
        trace('🗑️ Delete requested: ${ids.join(", ")}');
        
        for (nodeApi in nodes) {
            var data = untyped nodeApi.data;
            if (data != null) {
                var pathStr: String = untyped data.path;
                var parentPathStr = ProjectPanel.getParentPath(pathStr);
                
                try {
                    // ✅ Чистый вызов доменного сервиса!
                    fs.delete(new FilePath(pathStr));
                    trace('✅ Deleted: $pathStr');
                    invalidateChildrenCache(parentPathStr);
                } catch (e: Dynamic) {
                    trace('❌ Failed to delete: $e');
                    js.Browser.window.alert('Failed to delete: $e');
                }
            }
        }
    }

    private function handleCreate(parentId: String, index: Int, type: String): Void {
        var parent = findNodeById(state.treeData, parentId);
        var parentPathStr = if (parent != null) {
            var pd = untyped parent.data;
            pd != null ? untyped pd.path : null;
        } else null;
        
        if (parentPathStr == null) {
            var project = UseService.projectService().getCurrentProject();
            parentPathStr = project.rootPath.toString().split("\\").join("/");
        }
        
        var newName = js.Browser.window.prompt("Enter name:", "New " + type);
        if (newName == null || newName == "") return;
        
        var newPathStr = parentPathStr + "/" + newName;
        
        try {
            if (type == "folder") {
                fs.createDirectory(new FilePath(newPathStr));
            } else {
                // Для создания пустого файла можно использовать writeText
                fs.writeText(new FilePath(newPathStr), "");
            }
            trace('✅ Created: $newPathStr');
            invalidateChildrenCache(parentPathStr);
        } catch (e: Dynamic) {
            trace('❌ Failed to create: $e');
            js.Browser.window.alert('Failed to create: $e');
        }
    }

    private function handleMove(args: Dynamic): Void {
        var dragNodes: Array<Dynamic> = untyped args.dragNodes;
        var parentNode: Dynamic = untyped args.parentNode;
        
        var targetPathStr = if (parentNode != null) {
            var d = untyped parentNode.data;
            untyped d.path;
        } else {
            var project = UseService.projectService().getCurrentProject();
            project.rootPath.toString().split("\\").join("/");
        };
        
        for (n in dragNodes) {
            var d = untyped n.data;
            var srcPathStr: String = untyped d.path;
            var fileName = srcPathStr.split("/").pop();
            var destPathStr = targetPathStr + "/" + fileName;
            
            try {
                // ✅ Чистый вызов доменного сервиса!
                fs.move(new FilePath(srcPathStr), new FilePath(destPathStr));
                trace('✅ Moved: $srcPathStr -> $destPathStr');
                
                var srcParent = ProjectPanel.getParentPath(srcPathStr);
                invalidateChildrenCache(srcParent);
            } catch (e: Dynamic) {
                trace('❌ Failed to move: $e');
                js.Browser.window.alert('Failed to move: $e');
            }
        }
        invalidateChildrenCache(targetPathStr);
    }

    /**
    * Заменяет имя файла/папки в пути на новое.
    * Работает с обоими типами слэшей (Windows/Linux).
    */
    private static function replaceNameInPath(oldPath: String, newName: String): String {
        var lastSlashPos = Math.round(Math.max(oldPath.lastIndexOf("/"), oldPath.lastIndexOf("\\")));
        return if (lastSlashPos >= 0) {
            oldPath.substring(0, lastSlashPos + 1) + newName;
        } else {
            newName;
        }
    }

    /**
     * Возвращает родительский путь.
     */
    private static function getParentPath(path: String): Null<String> {
        var lastSlashPos = Math.round(Math.max(path.lastIndexOf("/"), path.lastIndexOf("\\")));
        return if (lastSlashPos >= 0) path.substring(0, lastSlashPos) else null;
    }

    /**
     * Очищает кэш детей для указанной папки и перезагружает её содержимое.
     */
     
   private function invalidateChildrenCache(folderPath: String): Void {
        trace('🔄 Invalidating cache for: $folderPath');
        
        // ✅ Запоминаем, была ли папка открыта
        var node = findNodeById(state.treeData, folderPath);
        var wasOpen = false;
        if (node != null) {
            wasOpen = untyped node.isOpen == true;
        }
        
        // ✅ НЕ сбрасываем isLoaded — просто помечаем как "загружается"
        var loadingData = updateNodeInTree(state.treeData, folderPath, {
            isLoading: true
        });
        
        setState({
            treeData: loadingData,
            isLoading: state.isLoading,
            selectedId: state.selectedId,
            contextMenu: state.contextMenu
        });
        
        // Запрашиваем детей заново
        service.readDir(folderPath).handle(function(children) {
            var arboristChildren = ProjectTreeAdapter.toArboristNodes(children);
            
            // ✅ Обновляем children, но НЕ трогаем isLoaded и isOpen
            var finalData = updateNodeInTree(state.treeData, folderPath, {
                children: arboristChildren,
                isLoading: false
            });
            
            setState({
                treeData: finalData,
                isLoading: state.isLoading,
                selectedId: state.selectedId,
                contextMenu: state.contextMenu
            });
            
            // ✅ Если папка была открыта — принудительно открываем через API
            if (wasOpen) {
                js.Browser.window.setTimeout(function() {
                    if (treeRef.current != null) {
                        untyped treeRef.current.open(folderPath);
                    }
                }, 50);
            }
        });
    }

    /**
     * Находит родительскую папку для пути и обновляет её кэш.
     */
    private function refreshParentDirectory(itemPath: String): Void {
        var parentPath = ProjectPanel.getParentPath(itemPath);
        if (parentPath != null) {
            invalidateChildrenCache(parentPath);
        } else {
            loadRoot();
        }
    }

    // ✅ onSelect получает МАССИВ выбранных узлов
    private function handleSelect(nodes: Array<Dynamic>): Void {
        if (nodes == null || nodes.length == 0) {
            setState({
                treeData: state.treeData,
                isLoading: state.isLoading,
                selectedId: null, 
                contextMenu: state.contextMenu 
            });
            return;
        }
        
        var firstNode = nodes[0];
        var newSelectedId = firstNode.id;
        
        trace('✅ Selected: $newSelectedId (${firstNode.data.name})');
        
        // Открываем файл при выборе
        if (firstNode.data.isLeaf == true) {
            UseService.eventBus().publish(ResourceOpened, new ResourceOpened(firstNode.data.path));
        }
        
        // ✅ Обновляем стейт — это триггерит перерисовку с новым selection
        setState({
            treeData: state.treeData,
            isLoading: state.isLoading,
            selectedId: newSelectedId, 
            contextMenu: state.contextMenu 
        });
    }
    // ===== ВЫНЕСЕННЫЙ ОБРАБОТЧИК ЛЕНИВОЙ ЗАГРУЗКИ =====
    
    /**
     * Обработчик onFetchChildren для react-arborist.
     * Вызывается при раскрытии папки с children=true.
     */
    private function handleFetchChildren(node: Dynamic, cb: Array<ArboristNode> -> Void): Void {
        if (node == null || node.data == null || node.data.path == null) {
            cb(untyped __js__("[]"));
            return;
        }

        service.readDir(node.data.path).handle(function(children) {
            var result: Array<ArboristNode> = untyped __js__("[]");
            if (children != null) {
                for (child in ProjectTreeAdapter.toArboristNodes(children)) {
                    untyped result.push(child);
                }
            }
            cb(result);
        });
    }

    // ===== Рендеринг узла =====

    // hide/presentation/ui/react/components/ProjectPanel.hx
    private var isDragging: Bool = false;
    private var dragStartPos: {x: Float, y: Float} = null;

    private function renderNode(api: NodeApi<Dynamic>): ReactElement {
       // ✅ ЧИТАЕМ ИЗ api.node, А НЕ ИЗ api!
        var node = untyped api.node;
        var style = untyped api.style;
        
        if (node == null) {
            trace('❌ api.node is null!');
            return jsx('<div style={{background:"red"}}>ERROR</div>');
        }
        
        var id: String = node.id;
        var data: Dynamic = node.data;
        var level: Int = node.level;
        var isSelected: Bool = node.isSelected;
        var isEditing: Bool = node.isEditing;
        var isOpen: Bool = node.isOpen;
        var isLeaf: Bool = node.isLeaf;
        
        // Проверка на root
        if (id == "__REACT_ARBORIST_INTERNAL_ROOT__") {
            return jsx('<div></div>');
        }
        
        if (data == null) {
            trace('❌ data is null for id=$id');
            return jsx('<div style={{background:"orange"}}>NO DATA</div>');
        }

        var name: String = untyped data.name;
        var extension: String = untyped data.extension;
        var isLoading: Bool = untyped data.isLoading;
        var isFolder: Bool = !isLeaf;



        var icon = if (!isFolder) {
            switch (extension) {
                case "hx": "🟦";
                case "json", "shadergraph": "📋";
                case "png", "jpg", "jpeg", "webp": "🖼️";
                case "scene", "prefab": "🎬";
                default: "📄";
            }
        } else {
            if (isOpen) "📂" else "📁";
        };

        // ✅ Стрелочка с учетом лоадера
        var arrow = if (!isFolder) {
            jsx('<span style={{width:"16px", display:"inline-block", marginRight:"4px", flexShrink: 0}}></span>');
        } else if (isLoading == true) {
            jsx('<span style={{width:"16px", textAlign:"center", fontSize:"10px", marginRight:"4px", color:"#facc15", flexShrink: 0}}>⏳</span>');
        } else {
            jsx('<span 
                style={{width:"16px", textAlign:"center", fontSize:"10px", marginRight:"4px", color:"#aaa", cursor:"pointer", flexShrink: 0}}
                onClick={function(e:js.html.MouseEvent) { e.stopPropagation(); node.toggle(); }}
            >{api.isOpen ? "▼" : "▶"}</span>');
        };  

        var rowStyle = {
            display: "flex", alignItems: "center", padding: "3px 8px",
            paddingLeft: (level * 16 + 8) + "px",
            background: isSelected ? "#2d5c8a" : "transparent",
            cursor: "pointer", borderRadius: "3px", whiteSpace: "nowrap",
            overflow: "hidden", textOverflow: "ellipsis", height: "24px", userSelect: "none"
        };

        var textStyle = {
            color: isSelected ? "#ffffff" : "#cccccc", flex: 1,
            overflow: "hidden", textOverflow: "ellipsis"
        };
        var content = if (isEditing) {
            jsx('
                <input 
                    autoFocus={true}
                    defaultValue={name}
                    style={{
                        background: "#1a1a1a",
                        border: "1px solid #007acc",
                        color: "#ffffff",
                        padding: "2px 6px",
                        borderRadius: "2px",
                        outline: "none",
                        fontSize: "13px",
                        flex: 1,
                        width: "100%",
                        boxSizing: "border-box"
                    }}
                    onKeyDown={function(e:js.html.KeyboardEvent) {
                        if (e.key == "Enter") {

                            untyped node.submit(e.target.value);
                        }
                        if (e.key == "Escape") {

                            untyped node.reset();
                        }
                    }}
                    onBlur={function(e:js.html.FocusEvent) {

                        untyped node.submit(e.target.value);
                    }}
                />
            ');
        } else {
            jsx('<span style={textStyle}>{name}</span>');
        };

        
        return jsx('
            <div style={rowStyle}
                onMouseDown={function(e:js.html.MouseEvent) {
                    dragStartPos = { x: e.clientX, y: e.clientY };
                    isDragging = false;
                }}
                onMouseMove={function(e:js.html.MouseEvent) {
                    if (dragStartPos != null) {
                        var dx = e.clientX - dragStartPos.x;
                        var dy = e.clientY - dragStartPos.y;
                        if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
                            isDragging = true;
                        }
                    }
                }}
                onClick={function(_:js.html.MouseEvent) {
                    if (!isDragging) {
                        untyped node.select();
                    }
                    isDragging = false;
                    dragStartPos = null;
                }}
                onContextMenu={function(e:js.html.MouseEvent) {
                    handleContextMenu(e, node);
                }}
            >
                {arrow}
                <span style={{marginRight: "6px", fontSize: "14px", flexShrink: 0}}>{icon}</span>
                {content}
            </div>
        ');
    }

    override function render(): ReactElement {
        if (state.isLoading) {
            return jsx('<div style={{padding:"10px", color:"#888"}}>Loading project tree...</div>');
        }

        var jsRootNodes: Array<ArboristNode> = untyped __js__("[]");
        for (node in state.treeData) untyped jsRootNodes.push(node);

        var ctxMenu = if (state.contextMenu != null) {
            jsx('
                <ContextMenu 
                    x={state.contextMenu.x} 
                    y={state.contextMenu.y} 
                    items={getContextMenuItems(state.contextMenu.node)}
                    onClose={closeContextMenu}
                />
            ');
        } else null;

        return jsx('
            <div style={{display: "flex", flexDirection: "column", height: "100%", background: "#383838"}}>
                <div style={{flex: 1, overflowY: "auto"}}>
                    <ReactArborist
                        data={jsRootNodes}
                        ref={treeRef}                 
                        selection={state.selectedId}
                        onRename={handleRename}
                        onCreate={handleCreate}
                        onDelete={handleDelete}
                        onMove={handleMove}
                        onSelect={handleSelect}
                        onToggle={handleToggle}
                        onContextMenu={function(e) { 
                            handleContextMenu(e, null);
                        }}      
                        openByDefault={false}
                        idAccessor="id"
                        indent={16}
                        rowHeight={24}
                        width={400}
                        height={600}
                        disableDrag={false}
                        disableDrop={false}
                    >
                        {renderNode}
                    </ReactArborist>
                </div>
                {ctxMenu}
            </div>
        ');
    }
}