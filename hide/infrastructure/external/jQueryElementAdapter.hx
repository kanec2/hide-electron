package hide.infrastructure.external;

import hide.domain.services.IElement;
/**
Адаптер для jQuery элементов (заглушка)
*/
class JQueryElementAdapter implements IElement {
    public function new() {}
    public function setInnerHtml(html:String):Void {}
    public function appendChild(child:IElement):Void {}
    public function addEventListener(event:String, handler:Dynamic->Void):Void {}
    public function getParent():Null<IElement> { return null; }
}