package hide.domain.services;

typedef Diagnostic = {
	var range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
	var severity:Int; // 1=Error, 2=Warning, 3=Info, 4=Hint
	var message:String;
	var ?source:String;
}
