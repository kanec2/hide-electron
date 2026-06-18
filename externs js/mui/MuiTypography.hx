package hide.infrastructure.external.mui;

import react.ReactComponent;

@:jsRequire("@mui/material", "Typography")
extern class MuiTypography extends ReactComponentOfProps<MuiTypographyProps> {}

typedef MuiTypographyProps = {
    var ?children:Dynamic;
    var ?variant:String; // "h1" | "h2" | "body1" | "body2" | etc.
    var ?color:String;
    var ?align:String; // "inherit" | "left" | "center" | "right" | "justify"
    var ?className:String;
    var ?sx:Dynamic;
}