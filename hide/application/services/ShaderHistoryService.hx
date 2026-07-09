package hide.application.services;

import hide.infrastructure.external.litegraph.LGraph;
import hx.injection.Service;
/**
    Сервис для управления историей изменений в Shader Editor.
    Реализует Undo/Redo функциональность.
    Изолирован от UI — работает только с состоянием графа.
*/
class ShaderHistoryService implements Service {
    private var undoStack:Array<String> = [];
    private var redoStack:Array<String> = [];
    private var maxUndoSteps:Int = 50;
    private var isUndoRedoInProgress:Bool = false;
    public function new() {}

    /**
        Сохраняет текущее состояние графа в undo stack.
        Вызывается перед каждым изменением.

        @param graph LiteGraph граф
    */
    public function saveState(graph:LGraph):Void {
        if (graph == null || isUndoRedoInProgress) return;
        
        try {
            var json = haxe.Json.stringify(graph.serialize());
            
            // Дедупликация: не сохраняем, если состояние не изменилось
            if (undoStack.length > 0 && undoStack[undoStack.length - 1] == json) {
                return;
            }
            
            undoStack.push(json);
            
            // Ограничиваем размер стека
            if (undoStack.length > maxUndoSteps) {
                undoStack.shift();
            }
            
            // Новое действие очищает redo stack
            redoStack = [];
        } catch (e:Dynamic) {
            trace('⚠️ [ShaderHistory] Failed to save state: $e');
        }
    }

    /**
        Отменяет последнее действие.

        @param graph LiteGraph граф
        @param onRestore Callback после восстановления (для обновления UI)
        @return true если undo выполнен успешно
    */
    public function undo(graph:LGraph, onRestore:Void->Void):Bool {
        if (undoStack.length == 0) {
            trace('⚠️ [ShaderHistory] Nothing to undo');
            return false;
        }
        
        try {
            isUndoRedoInProgress = true;
            
            // Сохраняем текущее состояние в redo
            redoStack.push(haxe.Json.stringify(graph.serialize()));
            
            // Восстанавливаем предыдущее состояние
            var json = undoStack.pop();
            graph.configure(haxe.Json.parse(json));
            
            if (onRestore != null) {
                onRestore();
            }
            
            trace('↶ Undo (${undoStack.length} states remaining)');
            isUndoRedoInProgress = false;
            return true;
        } catch (e:Dynamic) {
            trace('❌ [ShaderHistory] Undo error: $e');
            isUndoRedoInProgress = false;
            return false;
        } 
        
        
    }

    /**
        Повторяет отменённое действие.

        @param graph LiteGraph граф
        @param onRestore Callback после восстановления (для обновления UI)
        @return true если redo выполнен успешно
    */
    public function redo(graph:LGraph, onRestore:Void->Void):Bool {
        if (redoStack.length == 0) {
            trace('⚠️ [ShaderHistory] Nothing to redo');
            return false;
        }
        
        try {
            isUndoRedoInProgress = true;
            
            // Сохраняем текущее состояние в undo
            undoStack.push(haxe.Json.stringify(graph.serialize()));
            
            // Восстанавливаем следующее состояние
            var json = redoStack.pop();
            graph.configure(haxe.Json.parse(json));
            
            if (onRestore != null) {
                onRestore();
            }
            
            trace('↷ Redo (${redoStack.length} states remaining)');
            isUndoRedoInProgress = false;
            return true;
        } catch (e:Dynamic) {
            trace('❌ [ShaderHistory] Redo error: $e');
            isUndoRedoInProgress = false;
            return false;
        }
    }

    /**
    Проверяет, можно ли выполнить undo.
    */
    public function canUndo():Bool {
        return undoStack.length > 0;
    }

    /**
    Проверяет, можно ли выполнить redo.
    */
    public function canRedo():Bool {
        return redoStack.length > 0;
    }

    /**
    Очищает всю историю.
    */
    public function clear():Void {
        undoStack = [];
        redoStack = [];
    }

    /**
    Проверяет, находится ли сервис в процессе undo/redo.
    Используется для предотвращения рекурсивных вызовов.
    */
    public function get_isInProgress():Bool {
        return isUndoRedoInProgress;
    }
}