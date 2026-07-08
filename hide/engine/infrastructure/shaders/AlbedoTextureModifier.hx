// hide/engine/infrastructure/shaders/AlbedoTextureModifier.hx
package hide.engine.infrastructure.shaders;

import hxsl.Shader;

/**
Модифицирует albedoGamma, умножая на текстуру.
НЕ переопределяет PBR pipeline, а дополняет его.
*/
class AlbedoTextureModifier extends Shader {
    static var SRC = {
        @param var albedoTexture : Sampler2D;
        var albedoGamma : Vec3;  // ← Уже есть в BaseMesh, мы его модифицируем
        var calculatedUV : Vec2; // ← Уже есть в BaseMesh
        
        function fragment() {
            albedoGamma *= albedoTexture.get(calculatedUV).rgb;
        }
    };
    
    public function new() {
        super();
    }
}