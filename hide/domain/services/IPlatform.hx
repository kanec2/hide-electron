package hide.domain.services;
import hx.injection.Service;
interface IPlatform extends Service {
    function getAppArgs(): Array<String>;
}