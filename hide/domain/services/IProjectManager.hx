package hide.domain.services;

import tink.core.Future;
import hx.injection.Service;
import hide.domain.entities.Project;
import hide.domain.valueobjects.FilePath;

/**
 * Порт для управления жизненным циклом проектов.
 * Реализуется в Infrastructure (через Electron IPC).
 */
interface IProjectManager extends Service {
    /**
     * Открывает проект по пути.
     * На бэкенде это запустит AssetPipeline, LSP и загрузит метаданные.
     */
    function openProject(path:FilePath):Future<Project>;

    /**
     * Закрывает текущий проект.
     * Очищает кэши, останавливает вотчеры.
     */
    function closeProject():Future<Bool>;

    /**
     * Сохраняет настройки текущего проекта.
     */
    function saveProject(project:Project):Future<Bool>;

    /**
     * Создает новый проект в указанной директории.
     */
    function createProject(name:String, path:FilePath):Future<Project>;

    /**
     * Возвращает список недавних проектов (из настроек редактора).
     */
    function getRecentProjects():Future<Array<String>>;
}