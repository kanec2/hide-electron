package hide.domain.services;

typedef HoverInfo = {
	var contents:String;
	var ?range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
}
