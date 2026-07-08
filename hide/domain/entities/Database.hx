package hide.domain.entities;

/**
Сущность базы данных (для CDB или других данных)
*/
class Database {
    public final id:String;
    public final name:String;
    public function new(id:String, name:String) {
        this.id = id;
        this.name = name;
    }
}