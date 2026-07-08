package hide.application.dto;

typedef ResourceMetadataDto = {
    var id:String;
    var name:String;
    var type:String;
    var path:String;
    var ?size:Int;
    var ?modifiedAt:String;
}