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
    Use Case для сохранения шейдерного графа в файл.
    Отвечает только за файловые операции, не за UI.
*/
class SaveShaderUseCase implements Service {
    private var fileSystem:IFileSystem;
    private var fileDialog:IFileDialog;
    private var eventBus:IEventBus;

    public function new(fileSystem:IFileSystem, fileDialog:IFileDialog, eventBus:IEventBus) {
        this.fileSystem = fileSystem;
        this.fileDialog = fileDialog;
        this.eventBus = eventBus;
    }

    /**
        Сохраняет граф в указанный путь.

        @param graph LiteGraph граф
        @param graphCanvas LGraphCanvas для сохранения viewport
        @param path Путь к файлу
        @return Result с путём или ошибкой
    */
    public function saveToPath(graph:LGraph, graphCanvas:LGraphCanvas, path:String):Result<String, String> {
        try {
            var data = ShaderGraphSerializer.serialize(graph, graphCanvas);
            var json = ShaderGraphSerializer.toJson(data);
            fileSystem.writeText(new FilePath(path), json);
            
            trace('💾 [SaveShader] Saved to: $path');
            return Success(path);
        } catch (e:Dynamic) {
            var errorMsg = 'Failed to save shader: ${Std.string(e)}';
            trace('❌ [SaveShader] $errorMsg');
            return Failure(errorMsg);
        }
    }

    /**
        Показывает диалог "Save As" и сохраняет граф.

        @param graph LiteGraph граф
        @param graphCanvas LGraphCanvas для сохранения viewport
        @return Future с путём или null (если отменено)
    */
    public function saveAs(graph:LGraph, graphCanvas:LGraphCanvas):Future<Null<String>> {
        return fileDialog.showSave({
            filters: [
                { name: "Shader Graph", extensions: ["shadergraph", "json"] }
            ],
            defaultPath: "new_shader.shadergraph"
        }).flatMap(function(path:Null<String>) {
            if (path == null) {
                return Future.sync(null);
            }
            
            return switch (saveToPath(graph, graphCanvas, path)) {
                case Success(p): Future.sync(p);
                case Failure(e): 
                    trace('❌ [SaveShader] $e');
                    Future.sync(null);
            };
        });
    }
}