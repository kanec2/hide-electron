package hide.engine.infrastructure;

import h3d.scene.Mesh;
import h3d.scene.Interactive;
import h3d.scene.Scene;
import h3d.col.Ray;
import h3d.col.Bounds;
import js.html.CanvasElement;
import js.html.MouseEvent;

/**
	Отвечает за обработку ввода мыши в viewport'е.
	⚠️ ВАЖНО: Viewport рендерит сцену в RenderTexture, а затем blit'ит
	её на DOM canvas. Поэтому hxd.Window НЕ может обрабатывать события
	этого canvas (он работает только с оригинальным #webgl canvas).
	⚠️ ВАЖНО: Viewport рендерит сцену в RenderTexture (800x600),
	а camera.rayFromScreen() использует размеры engine'а (1920x1080).
	Поэтому мы вручную вычисляем ray через camera.unproject().
	ОТВЕТСТВЕННОСТЬ:
	Обработка кликов по mesh (через Interactive)
	Обработка кликов по пустому пространству
	Hover-эффекты (подсветка при наведении)
	НЕ ЗНАЕТ:
	Про Domain-объекты, выделение, события движка
	⚠️ НЕ является сервисом DI, потому что зависит от callback'ов,
	определяемых в runtime (в SceneViewportController).
 */
class InputHandler {
	private var isInteractiveClicked:Bool = false;
	private var onMeshClick:String->Void;
	private var onEmptyClick:Void->Void;
	private var onMeshHover:Mesh->Void;
	private var onMeshHoverOut:Mesh->Void;
	private var scene:Scene;
	private var meshToDomainId:Map<Mesh, String>;
	private var currentHoverMesh:Null<Mesh> = null;
	// Размеры RenderTexture (должны совпадать с Viewport)
	private var renderWidth:Int;
	private var renderHeight:Int;

	public function new(scene:Scene, meshToDomainId:Map<Mesh, String>, renderWidth:Int, renderHeight:Int, onMeshClick:String->Void, onEmptyClick:Void->Void,
			onMeshHover:Mesh->Void, onMeshHoverOut:Mesh->Void) {
		this.scene = scene;
		this.meshToDomainId = meshToDomainId;
		this.renderWidth = renderWidth;
		this.renderHeight = renderHeight;
		this.onMeshClick = onMeshClick;
		this.onEmptyClick = onEmptyClick;
		this.onMeshHover = onMeshHover;
		this.onMeshHoverOut = onMeshHoverOut;
	}

	public function attachCanvas(canvas:CanvasElement):Void {
		if (canvas == null) {
			trace("⚠️ [InputHandler] Cannot attach to null canvas");
			return;
		}

		trace('🎮 [InputHandler] Attaching to canvas 𝑐𝑎𝑛𝑣𝑎𝑠.𝑤𝑖𝑑𝑡ℎ𝑥canvas.widthx ${canvas.height}');
		trace(' Render target size: 𝑟𝑒𝑛𝑑𝑒𝑟𝑊𝑖𝑑𝑡ℎ𝑥renderWidthx ${renderHeight}');
		//trace(' Mesh count in map: ${meshToDomainId.length}');

		canvas.addEventListener("mousedown", function(e:MouseEvent) {
			if (e.button != 0)
				return;
            // ✅ ИСПРАВЛЕНО: СБРАСЫВАЕМ флаг в начале каждого клика!
            // Это гарантирует, что предыдущий клик не влияет на текущий.
            isInteractiveClicked = false;
			trace('🖱️ [InputHandler] mousedown at ({e.clientX}, ${e.clientY})');

			var hitMesh = raycastAtMouse(canvas, e);

			if (hitMesh != null) {
				var domainId = meshToDomainId.get(hitMesh);
				if (domainId != null) {
					isInteractiveClicked = true;
					trace('✅ [InputHandler] Clicked mesh with domainId: $domainId');
					onMeshClick(domainId);
				} else {
					trace('⚠️ [InputHandler] Mesh found but no domainId');
				}
			} else {
				trace('❌ [InputHandler] No mesh hit');
			}

			haxe.Timer.delay(function() {
				if (!isInteractiveClicked) {
					trace("❌ [InputHandler] Click on empty space");
					onEmptyClick();
				}
                // ✅ ИСПРАВЛЕНО: СБРАСЫВАЕМ флаг после обработки
                isInteractiveClicked = false;
			}, 0);
		});

		canvas.addEventListener("mousemove", function(e:MouseEvent) {
			var hitMesh = raycastAtMouse(canvas, e);

			if (hitMesh != currentHoverMesh) {
				if (currentHoverMesh != null) {
					onMeshHoverOut(currentHoverMesh);
				}

				if (hitMesh != null) {
					onMeshHover(hitMesh);
					canvas.style.cursor = "pointer";
				} else {
					canvas.style.cursor = "default";
				}

				currentHoverMesh = hitMesh;
			}
		});

		canvas.addEventListener("mouseleave", function(e:MouseEvent) {
			if (currentHoverMesh != null) {
				onMeshHoverOut(currentHoverMesh);
				currentHoverMesh = null;
				canvas.style.cursor = "default";
			}
		});

		trace("✅ [InputHandler] Canvas event listeners attached");
	}

	/**
		Делает raycast из камеры через позицию мыши на canvas.
		⚠️ ВАЖНО: camera.rayFromScreen() использует размеры engine'а,
		а не RenderTexture. Поэтому мы вручную вычисляем normalized coordinates
		и используем camera.unproject().
	 */
	private function raycastAtMouse(canvas:CanvasElement, e:MouseEvent):Null<Mesh> {
		var rect = canvas.getBoundingClientRect();
		// Координаты мыши относительно canvas (в CSS пикселях)
		var cssMouseX = e.clientX - rect.left;
		var cssMouseY = e.clientY - rect.top;
		// Конвертируем CSS-координаты в координаты RenderTexture
		var renderMouseX = cssMouseX * (renderWidth / rect.width);
		var renderMouseY = cssMouseY * (renderHeight / rect.height);
		trace('🔍 [InputHandler] Raycast:');
		trace(' CSS coords: (𝑐𝑠𝑠𝑀𝑜𝑢𝑠𝑒𝑋,cssMouseX, ${cssMouseY})');
		trace(' CSS rect: 𝑟𝑒𝑐𝑡.𝑤𝑖𝑑𝑡ℎ𝑥rect.widthx ${rect.height}');
		trace(' Render coords: (𝑟𝑒𝑛𝑑𝑒𝑟𝑀𝑜𝑢𝑠𝑒𝑋,renderMouseX, ${renderMouseY})');
		trace(' Render size: 𝑟𝑒𝑛𝑑𝑒𝑟𝑊𝑖𝑑𝑡ℎ𝑥renderWidthx ${renderHeight}');
		// ✅ ИСПРАВЛЕНО: вручную вычисляем normalized coordinates
		// nx, ny в диапазоне [-1, 1]
		var nx = (renderMouseX / renderWidth) * 2 - 1;
		var ny = (1 - renderMouseY / renderHeight) * 2 - 1;
		trace(' Normalized coords: (𝑛𝑥,nx, ${ny})');
		// ✅ ИСПРАВЛЕНО: используем camera.unproject() вместо rayFromScreen()
		// unproject() использует матрицы proj/view, которые не зависят от engine size
		var nearPoint = scene.camera.unproject(nx, ny, 0);
		var farPoint = scene.camera.unproject(nx, ny, 1);
		// Создаём ray из near → far
		var ray = new Ray();
		ray.px = nearPoint.x;
		ray.py = nearPoint.y;
		ray.pz = nearPoint.z;
		ray.lx = farPoint.x - nearPoint.x;
		ray.ly = farPoint.y - nearPoint.y;
		ray.lz = farPoint.z - nearPoint.z;
		@:privateAccess ray.normalize();
		trace(' Ray origin: (𝑟𝑎𝑦.𝑝𝑥,ray.px, ${ray.py}, 𝑟𝑎𝑦.𝑝𝑧)′);𝑡𝑟𝑎𝑐𝑒(′𝑅𝑎𝑦𝑑𝑖𝑟:(ray.pz) ′ );trace( ′ Raydir:(${ray.lx}, 𝑟𝑎𝑦.𝑙𝑦,ray.ly, ${ray.lz})');
		// Отладка bounds всех mesh'ей
		trace(' Checking {meshToDomainId.length} meshes:');
		for (mesh => domainId in meshToDomainId) {
			@:privateAccess mesh.syncPos();
			var bounds = mesh.getBounds();
			var collides = ray.collide(bounds);
			trace(' Mesh $domainId: bounds empty=${bounds.isEmpty()}, '
				+ 'min= ${bounds.xMin}, 𝑏𝑜𝑢𝑛𝑑𝑠.𝑦𝑀𝑖𝑛,bounds.yMin, ${bounds.zMin}), '
				+ 'max=(𝑏𝑜𝑢𝑛𝑑𝑠.𝑥𝑀𝑎𝑥,bounds.xMax, ${bounds.yMax}, ${bounds.zMax}), '
				+ 'collide=$collides');
		}
		return findClosestIntersection(ray);
	}

	/**
		Ищет ближайшее пересечение ray с mesh в сцене.
	 */
	private function findClosestIntersection(ray:Ray):Null<Mesh> {
		var closestMesh:Null<Mesh> = null;
		var closestDist:Float = Math.POSITIVE_INFINITY;
		for (mesh => domainId in meshToDomainId) {
			@:privateAccess mesh.syncPos();
			var bounds = mesh.getBounds();

			if (bounds.isEmpty()) {
				trace('⚠️ [InputHandler] Mesh domainId has empty bounds');
				continue;
			}

			if (ray.collide(bounds)) {
				var center = bounds.getCenter();
				var dx = center.x - ray.px;
				var dy = center.y - ray.py;
				var dz = center.z - ray.pz;
				var dist = dx * dx + dy * dy + dz * dz;

				trace(' ✅ Mesh 𝑑𝑜𝑚𝑎𝑖𝑛𝐼𝑑ℎ𝑖𝑡𝑎𝑡𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒domainIdhitatdistance ${Math.sqrt(dist)}');

				if (dist < closestDist) {
					closestDist = dist;
					closestMesh = mesh;
				}
			}
		}
		return closestMesh;
	}

	public function resetInteractiveClicked():Void {
		isInteractiveClicked = false;
	}
}