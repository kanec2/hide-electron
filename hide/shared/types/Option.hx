package shared.types;

/**
Option type для представления опциональных значений
*/
enum Option<T> {
    Some(value:T);
    None;
}