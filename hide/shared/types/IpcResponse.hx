package hide.shared.types;

// hide/main/ipc/IpcResponse.hx
typedef IpcResponse<T> = {
    var success:Bool;
    var ?error:String;
    var ?data:T;
}