package hide.infrastructure.platform.electron;

import hide.domain.services.IPlatform;

class ElectronPlatformAdapter implements IPlatform {
    public function new() {}
    
    public function getAppArgs():Array<String> {
        // В Electron аргументы доступны через process.argv, пропустим первые 2
        var argv:Array<String> = untyped process.argv;
        trace("ARRRGS:");
        trace(argv);
        return argv.length > 2 ? argv.slice(2) : [];
    }
}