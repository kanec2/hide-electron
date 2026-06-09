// hide/shared/events/ProjectClosing.hx

package hide.shared.events;
class ProjectClosing {
    public isCancelled:Bool;
    public function new(isCancelled:Bool) {
        this.isCancelled = isCancelled;
    }
}