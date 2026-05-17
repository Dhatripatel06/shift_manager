/// Base exception used by app services and repositories.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

class AuthRequiredException extends AppException {
  const AuthRequiredException()
      : super('Please sign in again to continue.');
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException()
      : super('You do not have permission to access this data.');
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}
