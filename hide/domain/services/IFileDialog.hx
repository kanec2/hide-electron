package hide.domain.services;

import tink.core.*;
import hx.injection.Service;

typedef FileFilter = {
    var name: String;
    var extensions: Array<String>;
}

/**
 * Доменный порт для показа диалога выбора файлов.
 * Реализуется в infrastructure для каждой платформы (Electron, NW.js).
 */
interface IFileDialog extends Service {
    /**
     * Показывает диалог открытия файла.
     * @return Future, который резолвится в путь к файлу или null, если диалог отменён.
     */
    function showOpen(?options: { ?filters: Array<FileFilter> }): Future<Null<String>>;
    
    /**
     * Показывает диалог сохранения файла.
     */
    function showSave(?options: { ?filters: Array<FileFilter>, ?defaultPath: String }): Future<Null<String>>;
    
    /**
     * Показывает диалог выбора директории.
     */
    function showDirectory(): Future<Null<String>>;
}