/// A repository answers with one of these and never throws.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) onSuccess, R Function(AppFailure) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final failure) => onFailure(failure),
      };
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}

/// Typed, never a bare string — the screen decides how to say it.
sealed class AppFailure {
  const AppFailure();
}

/// No collection has been run yet. Not an error: it is first use.
class IndexMissingFailure extends AppFailure {
  const IndexMissingFailure();
}

/// The file is there and cannot be read. [field] names what broke, so the
/// screen can say it instead of opening on an empty market.
class IndexUnreadableFailure extends AppFailure {
  const IndexUnreadableFailure(this.field, this.detail);

  final String field;
  final String detail;
}
