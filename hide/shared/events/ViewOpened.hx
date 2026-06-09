// hide/shared/events/ViewOpened.hx

package hide.shared.events;

import hide.domain.valueobjects.DisplayPosition;

class ViewOpened {
    public var viewName:String;
    public var state:Dynamic;
    public var position:DisplayPosition;
    public function new(viewName:String, state:Dynamic, position:DisplayPosition) {
        this.viewName = viewName;
        this.state = state;
        this.position = position;
    }
}