package hide.engine.infrastructure.shaders;

import h3d.shader.ScreenShader;

/**
 * Шейдер для вывода RenderTexture на экран через ScreenFx.
 * Наследуется от ScreenShader, добавляя поле texture.
 * 
 * ВАЖНО:
 * - НЕ переопределяем vertex() — базовый ScreenShader уже рисует fullscreen quad
 * - Добавляем только texture и переопределяем fragment()
 */
class TextureOutputShader extends ScreenShader {
    static var SRC = {
        @param var texture : Sampler2D;
        
        function fragment() {
            // calculatedUV и output.color уже есть в базовом ScreenShader
            output.color = texture.get(calculatedUV);
        }
    };
    
    public function new() {
        super();
    }
}