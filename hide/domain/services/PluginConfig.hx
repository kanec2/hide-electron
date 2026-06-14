package hide.domain.services;

typedef PluginConfig = {
    name:String,
    className:String,
    enabled:Bool,
    ?config:Dynamic
}