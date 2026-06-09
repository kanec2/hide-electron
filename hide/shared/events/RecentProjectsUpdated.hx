// hide/shared/events/RecentProjectsUpdated.hx

package hide.shared.events;
class RecentProjectsUpdated {
    public recentProjects:Array<String>;
    public function new(recentProjects:Array<String>) {
        this.recentProjects = recentProjects;
    }
}