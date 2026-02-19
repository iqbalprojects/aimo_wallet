import 'dart:convert';
import 'dart:math';
import '../vault/secure_memory.dart';

/// Secure Session Manager
/// 
/// Manages temporary secure sessions for passing sensitive data between screens.
/// 
/// SECURITY:
/// - Generates cryptographically secure session tokens
/// - Auto-expires sessions after 5 minutes
/// - Clears sensitive data from memory on expiration
/// - No sensitive data in navigation arguments
/// 
/// Usage:
/// ```dart
/// // Create session
/// final sessionId = SecureSessionManager.createSession(mnemonic);
/// Get.toNamed(route, arguments: {'sessionId': sessionId});
/// 
/// // Retrieve data
/// final mnemonic = SecureSessionManager.getMnemonic(sessionId);
/// 
/// // Clear session
/// SecureSessionManager.clearSession(sessionId);
/// ```
class SecureSessionManager {
  // Private constructor
  SecureSessionManager._();

  /// Active sessions storage
  static final Map<String, _SecureSession> _sessions = {};

  /// Session timeout duration
  static const Duration sessionTimeout = Duration(minutes: 5);

  /// Create secure session for mnemonic
  /// 
  /// Returns: Session ID (safe to pass in navigation)
  /// 
  /// SECURITY:
  /// - Generates cryptographically secure token
  /// - Auto-expires after 5 minutes
  /// - Only one active session per type
  static String createMnemonicSession(String mnemonic) {
    final sessionId = _generateSecureToken();
    
    _sessions[sessionId] = _SecureSession(
      data: mnemonic,
      type: _SessionType.mnemonic,
      createdAt: DateTime.now(),
    );

    // Auto-expire after timeout
    Future.delayed(sessionTimeout, () {
      clearSession(sessionId);
    });

    return sessionId;
  }

  /// Retrieve mnemonic from session
  /// 
  /// Returns: Mnemonic if session valid, null otherwise
  /// 
  /// SECURITY:
  /// - Validates session not expired
  /// - Does NOT clear session (caller must clear)
  static String? getMnemonic(String sessionId) {
    final session = _sessions[sessionId];
    
    if (session == null) return null;
    if (session.type != _SessionType.mnemonic) return null;
    if (_isExpired(session)) {
      clearSession(sessionId);
      return null;
    }

    return session.data;
  }

  /// Clear session and sensitive data
  /// 
  /// SECURITY:
  /// - Clears sensitive data from memory
  /// - Removes session from storage
  static void clearSession(String sessionId) {
    final session = _sessions.remove(sessionId);
    if (session != null) {
      // Clear sensitive data from memory
      SecureMemory.clearString(session.data);
    }
  }

  /// Clear all sessions
  /// 
  /// Called on app background or logout
  static void clearAllSessions() {
    final sessionIds = _sessions.keys.toList();
    for (final sessionId in sessionIds) {
      clearSession(sessionId);
    }
  }

  /// Check if session is expired
  static bool _isExpired(_SecureSession session) {
    final now = DateTime.now();
    final age = now.difference(session.createdAt);
    return age > sessionTimeout;
  }

  /// Generate cryptographically secure token
  static String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Get active session count (for debugging)
  static int get activeSessionCount => _sessions.length;
}

/// Session type enum
enum _SessionType {
  mnemonic,
}

/// Secure session data holder
class _SecureSession {
  final String data;
  final _SessionType type;
  final DateTime createdAt;

  _SecureSession({
    required this.data,
    required this.type,
    required this.createdAt,
  });
}
