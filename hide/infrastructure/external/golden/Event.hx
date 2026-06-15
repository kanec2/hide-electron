package hide.infrastructure.external.golden;

typedef Event<T> = {
	var name : String;
	var origin : T;
	function preventDefault() : Void;
}
