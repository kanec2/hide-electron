package hide.infrastructure.external.golden;
import hide.infrastructure.external.*;
extern class Tab {

	public var isActive : Bool;
	public var header : Header;
	// ✅ ЗАМЕНИТЕ ЭТУ СТРОКУ:
    // public var element : js.jquery.JQuery;
    public var element : Dynamic; // ← СТАЛО

	dynamic function onClose() : Bool;

}