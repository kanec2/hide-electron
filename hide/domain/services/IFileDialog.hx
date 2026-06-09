package hide.domain.services;
import tink.core.Future;
interface IFileDialog {
    function showOpen(options:Dynamic):Future<String>;
}