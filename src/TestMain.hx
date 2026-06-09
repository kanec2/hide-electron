import hx.injection.Service;
import hx.injection.ServiceCollection;
using hx.injection.ServiceExtensions; // Обязательно для методов addSingleton и т.д.

// ==========================================
// 1. ОПРЕДЕЛЕНИЕ ИНТЕРФЕЙСОВ (СЕРВИСОВ)
// ==========================================

interface ILogger extends Service {
    function log(message: String): Void;
}

interface IConfig extends Service {
    var appName: String;
}

// ==========================================
// 2. РЕАЛИЗАЦИЯ СЕРВИСОВ
// ==========================================

class ConsoleLogger implements ILogger {
    public function new() {} // Конструктор без аргументов
    
    public function log(message: String): Void {
        trace("[LOG] " + message);
    }
}

class AppConfig implements IConfig {
    public var appName: String = "HIDE IDE (Test Mode)";
    public function new() {}
}

// ==========================================
// 3. КЛАСС, КОТОРЫЙ ТРЕБУЕТ ЗАВИСИМОСТИ
// ==========================================

class Application implements Service {
    private var logger: ILogger;
    private var config: IConfig;

    // ВАРИАНТ А: Явное присваивание (классический Haxe)
    
    public function new(logger: ILogger, config: IConfig) {
        this.logger = logger;
        this.config = config;
    }

    public function run(): Void {
        logger.log("Запуск приложения: " + config.appName);
        logger.log("DI контейнер работает успешно!");
    }
}

// ==========================================
// 4. ТОЧКА ВХОДА (COMPOSITION ROOT)
// ==========================================

class TestMain {
    public static function main(): Void {
        // 1. Создаем коллекцию для регистрации зависимостей
        var collection = new ServiceCollection();

        // 2. Регистрируем сервисы
        // Когда кто-то запросит ILogger, мы отдадим ему экземпляр ConsoleLogger
        collection.addSingleton(ILogger, ConsoleLogger);
        
        // Когда кто-то запросит IConfig, мы отдадим AppConfig
        collection.addSingleton(IConfig, AppConfig);
        
        // Регистрируем само приложение. 
        // DI увидит, что Application требует ILogger и IConfig, и внедрит их автоматически.
        collection.addSingleton(Application);

        // 3. Создаем провайдер (он строит граф зависимостей)
        var provider = collection.createProvider();

        // 4. Запрашиваем главный класс. 
        // Магия происходит здесь: провайдер рекурсивно создает все зависимости.
        var app = provider.getService(Application);

        // 5. Используем приложение
        app.run();
    }
}