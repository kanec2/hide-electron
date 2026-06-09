// hide/shared/events/ProjectLoaded.hx

package hide.shared.events;
import hide.domain.entities.Project;

class ProjectLoaded {
    public var project:Project;
    public function new(project:Project) {
        this.project = project;
    }
}