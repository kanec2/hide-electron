// hide/domain/services/IViewFactory.hx

package hide.domain.services;

interface IViewFactory {
    /**
     * Создаёт view-компонент внутри указанного контейнера.
     */
    function create(container:IElement, state:Dynamic):Dynamic;
}