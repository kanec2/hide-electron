// hide/shared/events/RendererChanged.hx

package hide.shared.events;
class RendererChanged {
    public rendererName:String;
    public function new(rendererName:String) {
        this.rendererName = rendererName;
    }
}