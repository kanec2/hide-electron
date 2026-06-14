package hide.domain.services;
import hx.injection.Service;
interface IAppInfo extends Service {
    var version(get, never): String;
}