// hide/domain/services/IViewFactory.hx

package hide.domain.services;
import hx.injection.Service;
interface IViewFactory extends Service{
    /**
     * Создаёт view-компонент внутри указанного контейнера.
     */
    function create(container:IElement, state:Dynamic):Dynamic;
}