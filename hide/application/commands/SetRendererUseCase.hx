// hide/application/commands/SetRendererUseCase.hx

package hide.application.commands;

import hide.shared.types.IEventBus;
import hide.shared.events.RendererChanged;
import hx.injection.*;
class SetRendererUseCase implements Service {
    private var eventBus:IEventBus;

    public function new(eventBus:IEventBus) {
        this.eventBus = eventBus;
    }

    public function execute(rendererName:String):Void {
        // Смена рендерера — зависит от вашего проекта
        // Например: H3D.setRenderer(rendererName);
        eventBus.publish(new RendererChanged(rendererName));
    }
}