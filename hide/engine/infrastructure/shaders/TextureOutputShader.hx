package hide.engine.infrastructure.shaders;

import hxsl.Shader;
/**
Шейдер для вывода RenderTexture на экран через ScreenFx.
Рендерит fullscreen quad с текстурой.
*/
class TextureOutputShader extends Shader {
    static var SRC = {
    @param var texture : Sampler2D;
        function vertex() {
            // Fullscreen quad: используем стандартные атрибуты
            out.position = vec4(input.position.xy, 0, 1);
            calculatedUV = input.uv;
        }
        
        function fragment() {
            output.color = texture.get(calculatedUV);
        }
    };

    public function new() {
        super();
    }
}