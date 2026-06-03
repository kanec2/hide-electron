package hide.shared.types;

/**
 * Generic Result type to represent Success or Failure without throwing exceptions.
 * Used for cross-boundary communication between Application and Presentation layers.
 */
enum Result<T, E> {
    Success(value: T);
    Failure(error: E);
}