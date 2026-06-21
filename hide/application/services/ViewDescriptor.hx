package hide.application.services;

import hide.application.dto.ViewDto;
import hide.domain.services.IViewFactory;

/**
 * Атомарный дескриптор View: метаданные + фабрика.
 * Гарантирует, что нельзя зарегистрировать ViewDto без Factory (и наоборот).
 */
typedef ViewDescriptor = {
    var dto:ViewDto;
    var factory:IViewFactory;
}