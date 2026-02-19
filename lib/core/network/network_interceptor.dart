/// Network Interceptor
/// 
/// Responsibility: Intercept and log network requests/responses.
/// - Log requests for debugging
/// - Handle errors
/// - Add headers
/// 
/// Security: Never logs sensitive data (private keys, mnemonics)
abstract class NetworkInterceptor {
  /// Intercept request before sending
  Future<void> onRequest(Map<String, dynamic> request);

  /// Intercept response after receiving
  Future<void> onResponse(Map<String, dynamic> response);

  /// Handle network errors
  Future<void> onError(dynamic error);
}
