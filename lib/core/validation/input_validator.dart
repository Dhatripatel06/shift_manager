import '../errors/app_exception.dart';

class InputValidator {
  InputValidator._();

  static String requiredText(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('$fieldName is required.');
    }
    return trimmed;
  }

  static double nonNegativeDouble(String value, String fieldName) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      throw ValidationException('$fieldName must be a valid number.');
    }
    if (parsed < 0) {
      throw ValidationException('$fieldName cannot be negative.');
    }
    return parsed;
  }
}
