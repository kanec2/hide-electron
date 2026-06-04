// hide/domain/services/IPlugin.hx

package hide.domain.services;

import hide.application.services.ViewRegistry;
import hide.shared.types.IEventBus;

/**
 * Интерфейс плагина.
 * Плагин регистрирует себя в ViewRegistry и LayoutEngine.
 */
interface IPlugin {
    /**
     * Активирует плагин (регистрирует view, слушатели событий).
     */
    function activate(viewRegistry:ViewRegistry, eventBus:IEventBus):Void;

    /**
     * Деактивирует плагин (удаляет зарегистрированные ресурсы).
     */
    function deactivate():Void;
}