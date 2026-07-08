// hide/engine/infrastructure/SceneViewportController.hx
package hide.engine.infrastructure;

import hide.engine.domain.services.ISceneService;
import hide.engine.domain.services.IEngineEventBus;
import hide.engine.domain.entities.SceneObject;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.fwd.DirLight;
import hx.injection.Service;

/**
	Координатор viewport'а Scene Editor.
	ОТВЕТСТВЕННОСТЬ:
	Создание и инициализация h3d.scene.Scene
	Делегирование работы специализированным классам
	Управление жизненным циклом viewport'а
	Подписки на события движка
	ДЕЛЕГИРУЕТ:
	SceneGraphMapper — построение дерева объектов
	SelectionSystem — визуальное выделение
	InputHandler — обработка мыши
	⚠️ Рендеринг идёт в RenderTexture, а не напрямую на canvas.
	Поэтому InputHandler работает через raycast, а не через h3d.scene.Interactive.
 */
class SceneViewportController implements Service {
	private var sceneService:ISceneService;
	private var viewportService:ViewportService;
	private var engineEventBus:IEngineEventBus;
	private var scene:h3d.scene.Scene;
	private var sceneRoot:Object;
	private var viewport:Null<Viewport>;
	private var container:Dynamic;
	private var isAttached:Bool = false;
	// Специализированные сервисы (создаются вручную, не в DI)
	private var graphMapper:SceneGraphMapper;
	private var selectionSystem:SelectionSystem;
	private var inputHandler:InputHandler;

	public function new(sceneService:ISceneService, viewportService:ViewportService, engineEventBus:IEngineEventBus) {
		this.sceneService = sceneService;
		this.viewportService = viewportService;
		this.engineEventBus = engineEventBus;

		engineEventBus.onObjectSelected(onObjectSelected);
		engineEventBus.onSceneChanged(onSceneChanged);
	}

	public function attachTo(container:Dynamic):Void {
		this.container = container;

		var engine = h3d.Engine.getCurrent();
		if (engine == null || @:privateAccess engine.driver == null) {
			trace("⏳ [SceneViewport] Engine not ready, retrying in 50ms...");
			haxe.Timer.delay(function() attachTo(container), 50);
			return;
		}

		if (isAttached) {
			trace("⚠️ [SceneViewport] Already attached");
			return;
		}

		isAttached = true;

		// Создание сцены
		scene = new h3d.scene.Scene();
		scene.renderer.shadows = false;

		@:privateAccess scene.ctx.globals.fastSet(hxsl.Globals.allocID("shadow.proj"), new h3d.Matrix());

		sceneRoot = new h3d.scene.Object(scene);

		// Настройка камеры
		var camera = scene.camera;
		camera.pos.set(8, 8, 8);
		camera.target.set(0, 0, 0);
		camera.fovY = 45;
		camera.zNear = 0.1;
		camera.zFar = 1000;
		camera.update();

		// Свет
		var light = new DirLight(new h3d.Vector(-0.5, -0.5, -1), scene);

		// Инициализация специализированных сервисов
		graphMapper = new SceneGraphMapper();
		selectionSystem = new SelectionSystem(sceneRoot);

		// Регистрируем viewport
		var viewportWidth = 800;
		var viewportHeight = 600;
		viewport = viewportService.register("scene-editor", scene, viewportWidth, viewportHeight);
		container.appendChild(viewport.canvas);

		// ✅ ИСПРАВЛЕНО: Передаём размеры RenderTexture в InputHandler
		inputHandler = new InputHandler(scene, graphMapper.getMeshToDomainId(), viewportWidth, // renderWidth
			viewportHeight, // renderHeight
			onMeshClicked,
			onEmptySpaceClicked, onMeshHovered, onMeshHoverOut);

		// Привязываем обработчики к canvas
		inputHandler.attachCanvas(viewport.canvas);

		// Первичный рендер
		renderSceneInternal(sceneService.getRoot());

		trace("✅ [SceneViewportController] Attached to container");
	}

	private function onSceneChanged():Void {
		renderSceneInternal(sceneService.getRoot());
	}

	private function onObjectSelected(id:Null<String>):Void {
		if (id == null) {
			selectionSystem.clearSelectionVisuals();
		} else {
			if (graphMapper.getMeshToDomainId().iterator().hasNext()) {
				selectionSystem.updateSelectionVisuals(id, graphMapper.getMeshByDomainId);
			}
		}
	}

	private function onMeshClicked(domainId:String):Void {
		sceneService.select(domainId);
	}

	private function onEmptySpaceClicked():Void {
		sceneService.deselect();
	}

	private function onMeshHovered(mesh:Mesh):Void {
		selectionSystem.highlightMeshOnHover(mesh);
	}

	private function onMeshHoverOut(mesh:Mesh):Void {
		selectionSystem.restoreMeshColorOnHoverOut(mesh);
	}

	private function renderSceneInternal(root:SceneObject):Void {
		var savedSelectionId = selectionSystem.getCurrentSelectedId();

		selectionSystem.clearSelectionVisuals();

		var toRemove:Array<h3d.scene.Object> = [];
		for (child in sceneRoot) {
			if (child != sceneRoot)
				toRemove.push(child);
		}
		for (child in toRemove)
			child.remove();

		graphMapper.clear();
		graphMapper.buildObjectTree(root, sceneRoot);

		if (savedSelectionId != null) {
			haxe.Timer.delay(function() {
				selectionSystem.updateSelectionVisuals(savedSelectionId, graphMapper.getMeshByDomainId);
			}, 0);
		}
	}

	public function dispose():Void {
		if (viewport != null) {
			viewportService.removeViewport(viewport.id);
			viewport = null;
		}
	}
}