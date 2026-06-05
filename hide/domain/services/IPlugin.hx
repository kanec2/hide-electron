// hide/domain/services/IPlugin.hx
package hide.domain.services;

/**
 * Интерфейс доменного плагина.
 * Не знает ничего о ViewRegistry, EventBus или UI.
 */
interface IPlugin {
    /**
     * Инициализирует внутреннюю логику плагина.
     * Возвращает true, если инициализация прошла успешно.
     */
    function activate():Bool;
    
    /**
     * Очищает ресурсы плагина.
     */
    function deactivate():Void;
    
    /**
     * Имя плагина (для логирования и реестра).
     */
    var name(get, never):String;
}