/// Mirrors the backend's standard error envelope so every screen can show a
/// real message instead of a generic failure.
class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic> details;
  final String? correlationId;

  ApiException({required this.code, required this.message, this.details = const {}, this.correlationId});

  factory ApiException.fromEnvelope(Map<String, dynamic> error) {
    return ApiException(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? 'Something went wrong',
      details: (error['details'] as Map?)?.cast<String, dynamic>() ?? {},
      correlationId: error['correlation_id'] as String?,
    );
  }

  factory ApiException.network() => ApiException(code: 'NETWORK_ERROR', message: "Couldn't reach the server — check your connection");

  @override
  String toString() => message;
}
