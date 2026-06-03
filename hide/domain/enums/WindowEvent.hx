package hide.domain.enums;

/**
 * Типобезопасные события окна.
 * Заменяет строковые литералы "focus", "blur", "resize" и т.д.
 */
enum WindowEvent {
    Focus;
    Blur;
    Resize;
    Move;
    Maximize;
    Unmaximize;
    Minimize;
    Restore;
    Close;
}