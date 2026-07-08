// hide/engine/infrastructure/shaders/EmissiveModifier.hx
package hide.engine.infrastructure.shaders;

import hxsl.Shader;

/**
Модификатор emissive.
Аналогично legacy hrt.shader.EmissiveMult.
*/
class EmissiveModifier extends Shader {
    static var SRC = {
        @:import h3d.shader.BaseMesh;
        
        @param var emissiveColor : Vec3;
        @param var emissiveIntensity : Float;
        
        var emissive : Float;
        
        function fragment() {
            // Модифицируем emissive
            emissive = emissive + emissiveIntensity * dot(emissiveColor, vec3(0.333));
        }
    };
    
    public function new() {
        super();
        emissiveIntensity = 0.0;
        emissiveColor.set(0, 0, 0);
    }
}