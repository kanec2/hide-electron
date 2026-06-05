package hide.domain.services;

typedef PluginConfig = {
    name:String,
    class:String,
    enabled:Bool,
    ?config:Dynamic
}