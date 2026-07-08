package hide.domain.valueobjects;

/**
Уникальный идентификатор ресурса
*/
abstract ResourceId(String) from String to String {
    public function new(id:String) {
        if (id == null || id.length == 0) {
            throw "ResourceId cannot be null or empty";
        }
        this = id;
    }
}