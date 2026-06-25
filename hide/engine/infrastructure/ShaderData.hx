package hide.engine.infrastructure;

/**
 * Результат компиляции графа — набор параметров для шейдера.
 * Позже сюда добавим сгенерированный HXSL/GLSL код.
 */
typedef ShaderData = {
    var albedo: h3d.Vector;         // vec3
    var metallic: Float;            // 0..1
    var roughness: Float;           // 0..1
    var normal: h3d.Vector;         // vec3 (для normal map)
    var emissive: h3d.Vector;       // vec3
    var hasTexture: Bool;
    var texturePath: Null<String>;
    // Позже: var generatedCode: String;
}