package hide.domain.valueobjects;

/**
 * Неизменяемое значение, описывающее геометрию окна.
 * Не зависит от платформы, UI или внешних библиотек.
 */
typedef WindowBounds = {
    x: Int,
    y: Int,
    width: Int,
    height: Int
}