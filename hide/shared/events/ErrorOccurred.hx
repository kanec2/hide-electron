// hide/shared/events/ErrorOccurred.hx

package hide.shared.events;

typedef ErrorOccurred = {
    var context:String; // название Use-Case (например, "LoadProjectUseCase")
    var error:Dynamic;  // js.lib.Error, но Dynamic — safer для совместимости
}