// presentation/ui/react/components/AssetBrowserPanel.hx
package hide.presentation.ui.react.components;

import react.ReactComponent;
import react.ReactMacro.jsx;
import hide.presentation.ui.react.BaseReactComponent;
import hide.presentation.ui.react.hooks.UseService;
import hide.application.services.AssetBrowserService;
import hide.application.services.AssetBrowserService.AssetItem;

typedef AssetBrowserProps = {
    var initialState:Dynamic;
    var onUnmount:Void->Void;
}

typedef AssetBrowserState = {
    var items:Array<AssetItem>;
    var isLoading:Bool;
    var currentFolder:String; // Теперь это относительный путь внутри Assets
}

class AssetBrowserPanel extends BaseReactComponent<AssetBrowserProps, AssetBrowserState> {
    private var service:AssetBrowserService;

    public function new() {
        super();
        service = UseService.assetBrowser(); // Добавь этот хук в UseService.hx
        state = {
            items: [],
            isLoading: true,
            currentFolder: ""
        };
    }

    override function componentDidMount():Void {
        loadAssets("");
    }

    private function loadAssets(folder:String):Void {
        setState({ items: [], isLoading: true, currentFolder: folder });
        
        service.getAssets(folder).handle(function(items) {
            setState({
                items: items,
                isLoading: false,
                currentFolder: folder
            });
        });
    }

    private function getThumbnailUrl(item:AssetItem):String {
        // Если это картинка и у нее есть buildPath (webp), используем его
        // Иначе используем оригинальный путь с префиксом file://
        if (item.type == "image" && item.buildPath != null) {
            // Преобразуем путь в URL для Electron
            var path = item.buildPath.split("\\").join("/");
            return 'file:///$path';
        }
        return "";
    }

    override function render():ReactElement {
        var header: ReactElement =  (state.isLoading) ? jsx('<div style={{color:"#888"}}>Loading...</div>') : null;
        
        return jsx('
            <div style={{display: "flex", flexDirection: "column", height: "100%", width: "100%", background: "#252526", overflow: "hidden"}}>
                <div style={{padding: "8px", borderBottom: "1px solid #3e3e3e", display: "flex", alignItems: "center"}}>
                    <span style={{color: "#ccc", fontSize: "12px"}}>📁 {state.currentFolder}</span>
                    <button onClick={function(_) loadAssets(state.currentFolder)} style={{marginLeft: "auto", background: "transparent", border: "none", color: "#aaa", cursor: "pointer"}}>
                        🔄
                    </button>
                </div>
                
                <div style={{flex: 1, overflowY: "auto", padding: "10px", display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(100px, 1fr))", gap: "10px"}}>
                    {header}
                    
                    {[for (item in state.items) renderAssetItem(item)]}
                </div>
            </div>
        ');
    }

    private function renderAssetItem(item:AssetItem):ReactElement {
        var isImage = item.type == "image";
        var thumbnail = isImage ? getThumbnailUrl(item) : null;
        
        var content = if (thumbnail != null) {
            jsx('
                <div style={{width: "100%", height: "80px", background: "#1e1e1e", display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden", borderRadius: "4px"}}>
                    <img src={thumbnail} style={{maxWidth: "100%", maxHeight: "100%", objectFit: "contain"}} />
                </div>
            ');
        } else {
            jsx('
                <div style={{width: "100%", height: "80px", background: "#1e1e1e", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "4px", fontSize: "24px"}}>
                    {item.isDirectory ? "📁" : "📄"}
                </div>
            ');
        }

        return jsx('
            <div key={item.path} style={{cursor: "pointer", transition: "background 0.2s"}}
                onMouseOver={function(e:js.html.MouseEvent) untyped e.currentTarget.style.background = "#3e3e3e"}
                onMouseOut={function(e:js.html.MouseEvent) untyped e.currentTarget.style.background = "transparent"}
                onClick={function(_) handleItemClick(item)}
            >
                {content}
                <div style={{marginTop: "4px", fontSize: "11px", color: "#ccc", textAlign: "center", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis"}}>
                    {item.name}
                </div>
            </div>
        ');
    }

    private function handleItemClick(item:AssetItem):Void {
        if (item.isDirectory) {
            loadAssets(item.relativePath);
        } else {
            trace('Selected asset: ${item.name}');
            // Здесь можно опубликовать событие AssetSelected
        }
    }
}