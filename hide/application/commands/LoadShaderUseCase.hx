package hide.application.commands;

import hide.domain.services.IFileSystem;
import hide.domain.services.IFileDialog;
import hide.domain.valueobjects.FilePath;
import hide.engine.infrastructure.ShaderGraphSerializer;
import hide.infrastructure.external.litegraph.LGraph;
import hide.infrastructure.external.litegraph.LGraphCanvas;
import hide.shared.types.IEventBus;
import hide.shared.types.Result;
import hx.injection.Service;
import tink.core.*;
using tink.CoreApi;
/**
Результат загрузки шейдерного графа.
*/
typedef ShaderLoadResult = {
    var path:String;
    var graph:LGraph;
    var graphCanvas:LGraphCanvas;
}
    /**
    Use Case для загрузки шейдерного графа из файла.
    Отвечает только за файловые операции, не за UI.
    */
class LoadShaderUseCase implements Service {
    private var fileSystem:IFileSystem;
    private var fileDialog:IFileDialog;
    private var eventBus:IEventBus;
    public function new(fileSystem:IFileSystem, fileDialog:IFileDialog, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.fileDialog = fileDialog;
        this.eventBus = eventBus;
    }

    /**
    Загружает граф из указанного пути.

    @param graph LiteGraph граф (будет перезаписан)
    @param graphCanvas LGraphCanvas (будет обновлён viewport)
    @param path Путь к файлу
    @return Result с путём или ошибкой
    */
    public function loadFromPath(graph:LGraph, graphCanvas:LGraphCanvas, path:String):Result<String, String> {
        try {
            var json = fileSystem.readText(new FilePath(path));
            var data = ShaderGraphSerializer.fromJson(json);
            ShaderGraphSerializer.deserialize(data, graph, graphCanvas);
            
            trace('📂 [LoadShader] Loaded from: $path');
            return Success(path);
        } catch (e:Dynamic) {
            var errorMsg = 'Failed to load shader: ${Std.string(e)}';
            trace('❌ [LoadShader] $errorMsg');
            return Failure(errorMsg);
        }
    }

    /**
    Показывает диалог "Open" и загружает граф.

    @param graph LiteGraph граф (будет перезаписан)
    @param graphCanvas LGraphCanvas (будет обновлён viewport)
    @return Future с путём или null (если отменено)
    */
    public function loadWithDialog(graph:LGraph, graphCanvas:LGraphCanvas):Future<Null<String>> {
        return fileDialog.showOpen({
            filters: [
                { name: "Shader Graph", extensions: ["shadergraph", "json"] }
            ]
        }).flatMap(function(path:Null<String>) {
            if (path == null) {
                return Future.sync(null);
            }
            
            return switch (loadFromPath(graph, graphCanvas, path)) {
                case Success(p): Future.sync(p);
                case Failure(e): 
                    trace('❌ [LoadShader] $e');
                    Future.sync(null);
            };
        });
    }
}