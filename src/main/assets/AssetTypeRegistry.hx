package src.main.assets;

import js.node.Path;
using StringTools;
class AssetTypeRegistry {
    private var converters:Map<String, IAssetConverter> = new Map();
    
    public function new() {}
    
    public function register(converter:IAssetConverter):Void {
        for (ext in converter.supportedExtensions) {
            var normalizedExt = ext.toLowerCase();
            if (!normalizedExt.startsWith('.')) {
                normalizedExt = '.' + normalizedExt;
            }
            converters.set(normalizedExt, converter);
        }
    }
    
    public function getConverter(filePath:String):Null<IAssetConverter> {
        var ext = Path.extname(filePath).toLowerCase();
        return converters.get(ext);
    }
    
    public function getAllSupportedExtensions():Array<String> {
        var extensions:Array<String> = [];
        for (ext in converters.keys()) {
            extensions.push(ext);
        }
        return extensions;
    }
}