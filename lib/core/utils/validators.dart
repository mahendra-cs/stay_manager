/// Reusable form validation helpers.
///
/// Kept free of UI code so the same rules can be unit tested and reused across
/// every form in the app.
class Validators {
  const Validators._();

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(value.trim()) ? null : 'Enter a valid email address';
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// A percentage between 0 and 100 inclusive.
  static String? percentage(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return 'Enter a number';
    if (parsed < 0 || parsed > 100) return 'Enter a value between 0 and 100';
    return null;
  }

  static String? positiveInt(String? value, {String fieldName = 'Value'}) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return '$fieldName must be a whole number';
    if (parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  static String? nonNegativeNumber(
    String? value, {
    String fieldName = 'Value',
  }) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return '$fieldName must be a number';
    if (parsed < 0) return '$fieldName cannot be negative';
    return null;
  }

  /// A number strictly greater than zero (payment amounts, for example).
  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return '$fieldName must be a number';
    if (parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }

  /// Optional 24-hour `HH:mm` time.
  static String? timeOfDay(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    return pattern.hasMatch(value.trim()) ? null : 'Use 24-hour HH:mm format';
  }
}