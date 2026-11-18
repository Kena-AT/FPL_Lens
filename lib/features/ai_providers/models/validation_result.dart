/// Result of an AI provider key validation.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode; // 'invalid_key', 'no_vision', 'timeout', 'quota', 'network'
  final DateTime? validatedAt;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.validatedAt,
  });

  factory ValidationResult.success() => ValidationResult(
        isValid: true,
        validatedAt: DateTime.now(),
      );

  factory ValidationResult.failure(String message, [String? code]) =>
      ValidationResult(
        isValid: false,
        errorMessage: message,
        errorCode: code ?? 'invalid_key',
      );
}
