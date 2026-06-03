package hide.domain.services;

import hide.domain.valueobjects.FilePath;
import hide.domain.exceptions.FileNotFoundError;

/**
 * Порт (интерфейс) для файловой системы.
 * Не зависит от реализации (Electron, NW.js, Node, Browser).
 */
interface IFileSystem {
    /**
     * Проверяет существование файла/директории.
     * @throws FileNotFoundError если путь невалиден
     */
    function exists(path:FilePath):Bool;
    
    /**
     * Читает текстовый файл.
     * @throws FileNotFoundError если файл не найден
     * @throws IOError если ошибка чтения
     */
    function readText(path:FilePath):String;
    
    /**
     * Записывает текст в файл (создаёт директорию при необходимости).
     * @throws IOError если ошибка записи
     */
    function writeText(path:FilePath, content:String):Void;
    
    /**
     * Рекурсивно перечисляет файлы в директории.
     */
    function listFiles(path:FilePath, ?recursive:Bool):Array<FilePath>;
    
    /**
     * Возвращает абсолютный путь к директории данных приложения.
     */
    function getAppDataPath():FilePath;
}