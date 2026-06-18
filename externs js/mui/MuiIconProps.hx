package hide.infrastructure.external.mui;

typedef MuiIconProps = {
    var ?color:String; // "inherit" | "action" | "disabled" | "primary" | "secondary" | "error" | "info" | "success" | "warning"
    var ?fontSize:String; // "inherit" | "large" | "medium" | "small"
    var ?className:String;
    var ?sx:Dynamic;
}