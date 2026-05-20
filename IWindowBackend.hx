package ;
/**
 * Минимальный интерфейс для абстракции оконного бэкенда.
 * Позволяет переключаться между NW.js и Electron без изменения логики Ide.
 */
interface IWindowBackend {
    /**
     * Инициализация бэкенда (вызывается один раз при старте)
     */
    function init():Void;
    
    /**
     * Открытие нового окна / суб-вью
     * @param url URL для загрузки (например "app.html?subView=...")
     * @param options Опции окна (ширина, высота, id)
     * @param id Уникальный идентификатор окна (опционально)
     */
    function openWindow(url:String, options:Dynamic, ?id:String):Dynamic;
    
    /**
     * Регистрация глобального обработчика событий
     * @param channel Название канала/события
     * @param handler Функция-обработчик
     */
    function on(channel:String, handler:Dynamic->Void):Void;
    
    /**
     * Отправка события в главный процесс (или между окнами)
     * @param channel Название канала
     * @param ?data Данные для передачи
     */
    function send(channel:String, ?data:Dynamic):Void;
    
    /**
     * Очистка кэша приложения
     */
    function clearCache():Void;
    
    /**
     * Перезагрузка приложения
     */
    function reload():Void;
    
    /**
     * Получение текущего окна (для доступа к DOM/DevTools)
     */
    function getCurrentWindow():Dynamic;
}