// hide/shared/events/ViewOpened.hx

package hide.shared.events;

import hide.domain.valueobjects.DisplayPosition;

typedef ViewOpened = {
    var viewName:String;
    var state:Dynamic;
    var position:DisplayPosition;
}