/// A failed API call. [message] is always safe to show to the user.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const {},
  });

  /// Machine-readable, e.g. INVALID_CODE, EMAIL_NOT_VERIFIED, NETWORK_ERROR.
  final String code;
  final String message;
  final int? statusCode;

  /// Everything else the server sent in the error (retryAfter, email, ...).
  final Map<String, dynamic> details;

  bool get isNetwork => code == 'NETWORK_ERROR';

  int? get retryAfter => (details['retryAfter'] as num?)?.toInt();

  @override
  String toString() => message;
}