package hide.domain.services;

typedef CompletionItem = {
	var label:String;
	var kind:Int;
	var ?detail:String;
	var ?documentation:String;
	var ?insertText:String;
}
