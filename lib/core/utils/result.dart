import '../errors/app_exception.dart';

/// Lightweight result type for service boundaries.
class Result<T> {
  final T? data;
  final AppException? error;

  const Result._({this.data, this.error});

  bool get isSuccess => error == null;

  static Result<T> success<T>(T data) => Result<T>._(data: data);

  static Result<T> failure<T>(AppException error) =>
      Result<T>._(error: error);
}
