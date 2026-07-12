package src.main.assets;

import js.lib.Promise;

interface IAssetConverter {
    var supportedExtensions:Array<String>;
    
    function canConvert(path:String):Bool;
    
    function convert(sourcePath:String, meta:AssetMeta):Promise<ConversionResult>;
    
    function getPreview(sourcePath:String, ?size:Int):Promise<String>;
}