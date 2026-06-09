// hide/shared/events/ErrorOccurred.hx

package hide.shared.events;

class ErrorOccurred {
    public var context:String;
    public var error:Dynamic;
    public function new(context:String, error:Dynamic) {
        this.context = context;
        this.error = error;
    }
}