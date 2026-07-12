package src.main.assets;

/**
 * Структура .meta файла ассета.
 * Хранится рядом с исходным файлом в папке Assets/.
 */
/**
 * Результат работы конвертера.
 */
typedef ConversionResult = {
	var buildPath:String;
	var metadata:Dynamic;
	var ?error:String;
}
