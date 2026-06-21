// hide/application/services/IViewModule.hx
package hide.application.services;
import hide.application.dto.ViewDto;
import hide.domain.services.IViewFactory;
import hx.injection.Service;

/**
 * Модуль, отвечающий за регистрацию одного View.
 * Каждый View (Inspector, Hierarchy, Scene и т.д.) имеет свой модуль.
 */
interface IViewModule extends Service {
    /**
     * Возвращает дескриптор View (метаданные + фабрика).
     */
    function getDescriptor():ViewDescriptor;
}

