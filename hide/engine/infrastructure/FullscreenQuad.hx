package hide.engine.infrastructure;

import h3d.mat.Texture;
import js.html.webgl.RenderingContext;
import js.html.webgl.Shader;
import js.html.webgl.Program;
import js.html.webgl.Buffer;
import js.html.webgl.UniformLocation;
import js.html.webgl.Texture as GLTexture;

/**
	GPU-only fullscreen quad для рендеринга текстуры на canvas.
	Заменяет CPU blit (capturePixels → putImageData).
	Использует:
	Vertex shader: рисует полноэкранный quad (triangle strip, 4 вершины)
	Fragment shader: сэмплирует текстуру и выводит на экран
	Результат: рендеринг происходит полностью на GPU без чтения пикселей в CPU.
 */
class FullscreenQuad {
	private var gl:RenderingContext;
	private var program:Program;
	private var vertexBuffer:Buffer;
	private var textureLocation:UniformLocation;
	private var positionLocation:Int;
	private var isInitialized:Bool = false;

	// Vertex shader: рисуем полноэкранный quad в NDC [-1, 1]
	private static var VERTEX_SHADER = "
    attribute vec2 aPosition;
    varying vec2 vUV;
    void main() {
        // Конвертируем [-1,1] → [0,1] для UV
        vUV = aPosition * 0.5 + 0.5;
        // Инвертируем Y, т.к. WebGL и Heaps имеют разную ориентацию
        vUV.y = 1.0 - vUV.y;
        gl_Position = vec4(aPosition, 0.0, 1.0);
    }
";

	// Fragment shader: сэмплируем текстуру
	private static var FRAGMENT_SHADER = "
    precision mediump float;
    varying vec2 vUV;
    uniform sampler2D uTexture;
    void main() {
        gl_FragColor = texture2D(uTexture, vUV);
    }
";

	public function new(gl:RenderingContext) {
		this.gl = gl;
	}

	/**
		Инициализирует shader program и vertex buffer.
		Вызывается один раз при создании viewport'а.
	 */
	public function init():Void {
		if (isInitialized)
			return;

		// 1. Компилируем шейдеры
		var vs = compileShader(RenderingContext.VERTEX_SHADER, VERTEX_SHADER);
		var fs = compileShader(RenderingContext.FRAGMENT_SHADER, FRAGMENT_SHADER);

		if (vs == null || fs == null) {
			trace("❌ [FullscreenQuad] Shader compilation failed");
			return;
		}

		// 2. Линкуем программу
		program = gl.createProgram();
		gl.attachShader(program, vs);
		gl.attachShader(program, fs);
		gl.linkProgram(program);

		if (gl.getProgramParameter(program, RenderingContext.LINK_STATUS) == false) {
			trace("❌ [FullscreenQuad] Program link failed: " + gl.getProgramInfoLog(program));
			return;
		}

		// 3. Получаем locations атрибутов и uniform'ов
		positionLocation = gl.getAttribLocation(program, "aPosition");
		textureLocation = gl.getUniformLocation(program, "uTexture");

		// 4. Создаём vertex buffer с 4 вершинами fullscreen quad
		vertexBuffer = gl.createBuffer();
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, vertexBuffer);

		// Triangle strip: 4 вершины покрывают весь экран в NDC [-1,1]
		var vertices = new js.lib.Float32Array([
			 -1.0,  -1.0, // bottom-left
			  1.0, -1.0, // bottom-right
			- 1.0,      1.0, // top-left
			  1.0,   1.0, // top-right
		]);
		gl.bufferData(RenderingContext.ARRAY_BUFFER, vertices, RenderingContext.STATIC_DRAW);

		// 5. Удаляем шейдеры (они уже скомпилированы в программу)
		gl.deleteShader(vs);
		gl.deleteShader(fs);

		isInitialized = true;
		trace("✅ [FullscreenQuad] Initialized");
	}

	/**
		Компилирует шейдер из исходного кода.
	 */
	private function compileShader(type:Int, source:String):Null<Shader> {
		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		if (gl.getShaderParameter(shader, RenderingContext.COMPILE_STATUS) == false) {
			trace("❌ [FullscreenQuad] Shader compile error: " + gl.getShaderInfoLog(shader));
			gl.deleteShader(shader);
			return null;
		}

		return shader;
	}

	/**
		Рендерит текстуру на весь canvas через GPU.

		@param texture RenderTexture, в которую была отрендерена сцена
	 */
	public function render(texture:Texture):Void {
		if (!isInitialized || texture == null)
			return;

		// Получаем GPU handle текстуры (WebGL texture object)
		var glTexture:GLTexture = cast texture.getHandle();
		if (glTexture == null) {
			trace("⚠️ [FullscreenQuad] Texture handle is null");
			return;
		}

		// Устанавливаем viewport на весь canvas
		gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

		// Очищаем canvas
		gl.clearColor(0.1, 0.1, 0.1, 1.0);
		gl.clear(RenderingContext.COLOR_BUFFER_BIT);

		// Используем нашу программу
		gl.useProgram(program);

		// Привязываем текстуру к texture unit 0
		gl.activeTexture(RenderingContext.TEXTURE0);
		gl.bindTexture(RenderingContext.TEXTURE_2D, glTexture);
		gl.uniform1i(textureLocation, 0);

		// Настраиваем vertex attributes
		gl.bindBuffer(RenderingContext.ARRAY_BUFFER, vertexBuffer);
		gl.enableVertexAttribArray(positionLocation);
		gl.vertexAttribPointer(positionLocation, 2, RenderingContext.FLOAT, false, 0, 0);

		// ✅ Рендерим fullscreen quad (triangle strip, 4 вершины)
		gl.drawArrays(RenderingContext.TRIANGLE_STRIP, 0, 4);

		// Очищаем состояние WebGL
		gl.disableVertexAttribArray(positionLocation);
		gl.bindTexture(RenderingContext.TEXTURE_2D, null);
		gl.useProgram(null);
	}

	/**
		Освобождает GPU ресурсы.
	 */
	public function dispose():Void {
		if (program != null) {
			gl.deleteProgram(program);
			program = null;
		}
		if (vertexBuffer != null) {
			gl.deleteBuffer(vertexBuffer);
			vertexBuffer = null;
		}
		isInitialized = false;
	}
}