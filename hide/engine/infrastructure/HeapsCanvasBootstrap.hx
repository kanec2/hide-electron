package hide.engine.infrastructure;

// infrastructure/HeapsCanvasBootstrap.hx
class HeapsCanvasBootstrap {
    public static function ensureWebGlCanvas():Void {
        if (js.Browser.document.getElementById("webgl") == null) {
            var canvas = js.Browser.document.createCanvasElement();
            canvas.id = "webgl";
            canvas.width = 16;
            canvas.height = 16;
            canvas.style.position = "absolute";
            canvas.style.top = "-9999px";
            canvas.style.left = "-9999px";
            canvas.style.visibility = "hidden";
            js.Browser.document.body.appendChild(canvas);
        }
    }
}