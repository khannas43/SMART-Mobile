import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';
import 'raj_sso_auth_service.dart';
import 'role/role_context.dart';

/// Activity 2.6 — secure JWT persistence and session lifecycle.
///
/// JWT claim parsing lives in [AuthSession] (activity 2.7).
/// HTTP headers are applied by [SmartApiClient] from this service.
class AuthService extends ChangeNotifier {
  AuthService._({
    FlutterSecureStorage? storage,
    bool skipEnvChecks = false,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _skipEnvChecks = skipEnvChecks;

  /// In-memory / mocked storage for unit tests (activity 2.14).
  @visibleForTesting
  factory AuthService.forTest({FlutterSecureStorage? storage}) =>
      AuthService._(storage: storage, skipEnvChecks: true);

  static final AuthService instance = AuthService._();

  static const _tokenKey = 'smart_jwt';

  final FlutterSecureStorage _storage;
  final bool _skipEnvChecks;
  AuthSession? _session;

  /// Current session, or null when logged out / invalid token.
  AuthSession? get session => _session;

  String? get accessToken => _session?.token;

  bool get isAuthenticated =>
      _session != null && _session!.token.isNotEmpty && !_session!.isExpired;

  /// Load token from secure storage (call once at app startup).
  Future<void> initialize() async {
    final stored = await _storage.read(key: _tokenKey);
    _applyToken(stored, persist: false);
  }

  /// Whether a JWT is stored on disk (activity 2.12 persistence check).
  Future<bool> hasStoredToken() async {
    final stored = await _storage.read(key: _tokenKey);
    return stored != null && stored.trim().isNotEmpty;
  }

  /// Save JWT after SSO login or sandbox token fetch.
  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    await _storage.write(key: _tokenKey, value: trimmed);
    _applyToken(trimmed, persist: false);
  }

  /// User-initiated logout: Raj SSO sign-out proxy, then clear local JWT (activity 3.9).
  Future<void> logout() async {
    _sessionEndedMessage = null;
    final userdetails = _session?.userdetailsForSignOut;
    if (userdetails != null && userdetails.isNotEmpty) {
      await RajSsoAuthService.instance.signOut(userdetails: userdetails);
    }
    await clearToken();
  }
  /// Called when the backend rejects the JWT (HTTP 401) or local [exp] passes.
  Future<void> endSession({String? message}) async {
    _sessionEndedMessage =
        message ?? 'Your session has expired. Please sign in again.';
    await clearToken();
  }

  /// Clears session when JWT [exp] has passed (activity 3.10).
  ///
  /// Returns `true` when the session was expired and cleared.
  Future<bool> expireSessionIfNeeded({String? message}) async {
    final session = _session;
    if (session == null || !session.isExpired) return false;
    await endSession(message: message);
    return true;
  }

  String? _sessionEndedMessage;

  /// Set when [endSession] runs; cleared after the UI shows it.
  String? get sessionEndedMessage => _sessionEndedMessage;

  void acknowledgeSessionEnded() {
    _sessionEndedMessage = null;
  }

  Future<void> clearToken() async {
    _session = null;
    await _storage.delete(key: _tokenKey);
    await RoleContext.instance.clear();
    notifyListeners();
  }

  void _applyToken(String? token, {required bool persist}) {
    final next = AuthSession.fromToken(token);
    if (next != null && next.isExpired) {
      _session = null;
      if (!persist) {
        _storage.delete(key: _tokenKey);
      }
    } else {
      _session = next;
    }
    notifyListeners();
  }

  // ── Delegates to [AuthSession] for callers / interceptors ─────────────────

  String get currentRole => _session?.currentRole ?? 'CITIZEN';

  String? get ssoId => _session?.ssoId;

  String? get smUserId => _session?.smUserId;

  String? get userName => _session?.userName;

  String? get departmentCode => _session?.departmentCode;

  /// JWT `sub` claim — encrypted SSO userdetails for sign-out (activity 3.9).
  String? get userdetailsForSignOut => _session?.userdetailsForSignOut;
}
