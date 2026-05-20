package hide.modules;
import hide.core.Ide;

class UiLayout {
    var ide:Ide;
    public function new(ide:Ide) { this.ide = ide; }
    
    public function loadFromXml(xml:Xml):Void {
        trace("[ProjectManager] loadFromXml: " + xml + " items");
        // Заглушка: в Electron будет парсить XML и отправлять в main
        ide.getBackend().createMenu(xml);
    }
    
    public function trigger(itemId:String):Void {
        trace("[ProjectManager] trigger: " + itemId);
        // Здесь будет логика вызова команд
    }
}