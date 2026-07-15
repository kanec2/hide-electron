package src.main.services;
import src.main.assets.*;
import src.main.assets.registry.*;
import src.main.assets.converters.ImageConverter;
import src.main.lsp.HaxeLanguageServerManager;
// hide/main/services/ServiceLocator.hx
class ServiceLocator {
    private static var _instance:ServiceLocator;
    
    // Явные поля вместо динамического Map (типобезопасность!)
    public var assetPipeline(default, null):Null<AssetPipelineService>;
    public var lspManager(default, null):Null<HaxeLanguageServerManager>;
    
    private function new() {}
    
    public static function get():ServiceLocator {
        if (_instance == null) _instance = new ServiceLocator();
        return _instance;
    }
    
    // Метод инициализации вместо автоматического резолвинга
    public static function init():Void {
        var loc = get();
        
        // Явное создание зависимостей (как factory method)
        var registry = new AssetTypeRegistry();
        registry.register(new ImageConverter());
        
        loc.assetPipeline = new AssetPipelineService(registry);
        loc.lspManager = new HaxeLanguageServerManager();
        
        trace("✅ [ServiceLocator] Main Process services ready");
    }
}