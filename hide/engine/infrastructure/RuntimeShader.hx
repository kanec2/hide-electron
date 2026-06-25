// engine/infrastructure/RuntimeShader.hx
package hide.engine.infrastructure;

import h3d.shader.Shader;

/**
 * Кастомный шейдер, сгенерированный из графа нод.
 * Параметры (uniform'ы) обновляются из нод.
 */
class RuntimeShader extends h3d.shader.Shader {
    // Uniform'ы, которые будут доступны в шейдере
    @:param var albedoColor : Vec3;
    @:param var metallicValue : Float;
    @:param var roughnessValue : Float;
    @:param var emissiveColor : Vec3;
    
    static var SRC = {
        function fragment() {
            // Простая PBR-подобная модель
            var N = normalize(input.normal);
            var L = normalize(directionalLight.direction);
            var V = normalize(camera.position - input.position);
            
            // Diffuse (Lambert)
            var NdotL = max(0.0, dot(N, L));
            var diffuse = albedoColor * NdotL;
            
            // Простой specular (Blinn-Phong вместо настоящего PBR)
            var H = normalize(L + V);
            var NdotH = max(0.0, dot(N, H));
            var specPower = (1.0 - roughnessValue) * 64.0;
            var specular = pow(NdotH, specPower) * (1.0 - roughnessValue);
            
            // Металлик смешивает diffuse и specular
            var finalColor = lerp(diffuse, specular * albedoColor, metallicValue);
            finalColor += emissiveColor;
            
            output.color = vec4(finalColor, 1.0);
        }
    };
    
    public function new() {
        super();
        // Дефолтные значения
        albedoColor.set(0.8, 0.8, 0.8);
        metallicValue = 0.0;
        roughnessValue = 0.5;
        emissiveColor.set(0, 0, 0);
    }
}