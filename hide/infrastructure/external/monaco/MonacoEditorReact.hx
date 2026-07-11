package hide.infrastructure.external.monaco;

import react.ReactComponent;

/**
 * Extern для @monaco-editor/react
 * https://github.com/suren-atoyan/monaco-react
 */
@:jsRequire('@monaco-editor/react', 'default')
extern class MonacoEditor extends ReactComponentOfProps<MonacoEditorProps> {}

typedef MonacoEditorProps = {
    /** Высота редактора */
    var height:String;
    
    /** Ширина редактора */
    var ?width:String;
    
    /** Язык по умолчанию */
    var ?defaultLanguage:String;
    
    /** Значение по умолчанию */
    var ?defaultValue:String;
    
    /** Текущее значение (controlled mode) */
    var ?value:String;
    
    /** Язык модели */
    var ?language:String;
    
    /** Путь модели (для multi-model editor) */
    var ?path:String;
    
    /** Тема редактора */
    var ?theme:String;
    
    /** Опции Monaco Editor */
    var ?options:Dynamic;
    
    /** Callback при изменении содержимого */
    var ?onChange:String->Dynamic->Void;
    
    /** Callback при монтировании редактора */
    var ?onMount:Dynamic->Dynamic->Void;
    
    /** Callback перед монтированием */
    var ?beforeMount:Dynamic->Void;
    
    /** Callback при валидации */
    var ?onValidate:Dynamic->Void;
    
    /** Сохранять состояние вида при переключении моделей */
    var ?saveViewState:Bool;
    
    /** Класс для контейнера */
    var ?className:String;
    
    /** Индикатор загрузки */
    var ?loading:Dynamic;
}

/**
 * Загрузчик Monaco
 */
@:jsRequire('@monaco-editor/react', 'loader')
extern class MonacoLoader {
    /**
     * Настройка загрузчика Monaco
     */
    static function config(options:LoaderConfig):Void;
    
    /**
     * Инициализация Monaco
     */
    static function init():js.lib.Promise<Dynamic>;
}

typedef LoaderConfig = {
    /** Путь к папке с Monaco */
    var ?paths:{
        var vs:String;
    };
    
    /** Использовать локальную версию Monaco */
    var ?monaco:Dynamic;
    
    /** Конфигурация локалей */
    @:optional
    @:native('vs/nls')
    var vsNls:Dynamic;
}