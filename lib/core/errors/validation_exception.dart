/// Domain error used for invalid input that must be surfaced to the user.
class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}