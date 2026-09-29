import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/providers.dart';
import 'auth_repository.dart';

enum SessionStatus { loading, unauthenticated, authenticated }

class SessionState {
  final SessionStatus status;
  final String? role;
  final Map<String, dynamic>? profile; // GET /residents/me payload

  const SessionState({required this.status, this.role, this.profile});

  const SessionState.loading() : this(status: SessionStatus.loading);
  const SessionState.unauthenticated() : this(status: SessionStatus.unauthenticated);

  String get accountState => (profile?['account_state'] as String?) ?? 'Pending';
  bool get hasProfile => (profile?['full_name'] as String?)?.isNotEmpty == true;
  bool get isActiveResident => role == 'resident' && accountState == 'Active';
}

class SessionController extends StateNotifier<SessionState> {
  final Ref ref;
  SessionController(this.ref) : super(const SessionState.loading()) {
    _bootstrap();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _bootstrap() async {
    final storage = ref.read(authStorageProvider);
    final token = await storage.accessToken;
    final role = await storage.role;
    if (token == null) {
      state = const SessionState.unauthenticated();
      return;
    }
    try {
      final profile = await _repo.getMe();
      state = SessionState(status: SessionStatus.authenticated, role: role, profile: profile);
      _registerFcmToken();
    } catch (_) {
      await storage.clear();
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> onVerified(Map<String, dynamic> user) async {
    state = SessionState(status: SessionStatus.authenticated, role: user['role'] as String, profile: null);
    await refreshProfile();
    _registerFcmToken();
  }

  /// Best-effort: push registration should never block login or session bootstrap.
  void _registerFcmToken() {
    () async {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission();
        final token = await messaging.getToken();
        if (token != null) await _repo.sendFcmToken(token);
        messaging.onTokenRefresh.listen((t) => _repo.sendFcmToken(t));
      } catch (_) {
        // No Firebase config yet, permission denied, or offline — fine, not fatal.
      }
    }();
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _repo.getMe();
      state = SessionState(status: SessionStatus.authenticated, role: state.role, profile: profile);
    } catch (_) {
      // Keep prior state — a transient profile-fetch failure shouldn't log the user out.
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const SessionState.unauthenticated();
  }
}

final sessionControllerProvider = StateNotifierProvider<SessionController, SessionState>((ref) => SessionController(ref));
