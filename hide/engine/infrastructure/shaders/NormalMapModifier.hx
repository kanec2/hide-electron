// hide/engine/infrastructure/shaders/NormalMapModifier.hx
package hide.engine.infrastructure.shaders;

import hxsl.Shader;

/**
Модификатор normal map.
НЕ переопределяет PBR pipeline — только добавляет normal mapping.
Аналогично legacy hrt.shader.TextureMult.
*/
class NormalMapModifier extends Shader {
    static var SRC = {
        @:import h3d.shader.BaseMesh;  // ← импортируем переменные из BaseMesh
        
        @param var normalTexture : Sampler2D;
        @param var normalStrength : Float;
        
        // Эти переменные УЖЕ есть в BaseMesh — мы их МОДИФИЦИРУЕМ
        //var transformedNormal : Vec3;
        var calculatedUV : Vec2;
        
        function fragment() {
            // Unpack normal map: [0,1] → [-1,1]
            var n = normalTexture.get(calculatedUV).rgb;
            n = n * 2.0 - 1.0;
            n.xy *= normalStrength;
            n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
            n = normalize(n);
            
            // Модифицируем transformedNormal (не заменяем полностью!)
            transformedNormal = normalize(transformedNormal + n * normalStrength);
        }
    };
    
    public function new() {
        super();
        normalStrength = 1.0;
    }
}