package hide.domain.exceptions;

class InvalidConfigError extends haxe.Exception {
    public function new(message:String) {
        super('Invalid configuration: $message');
    }
}