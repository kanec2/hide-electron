package hide.shared.events;

import hide.domain.valueobjects.LayoutState;

class LayoutSaved {
    public var state:LayoutState;
    public function new(state:LayoutState) {
        this.state = state;
    }
}