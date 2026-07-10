package hide.domain.services;

typedef Location = {
	var uri:String;
	var range:{start:{line:Int, character:Int}, end:{line:Int, character:Int}};
}
