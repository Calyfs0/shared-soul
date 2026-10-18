import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  String? get userId => user?.id;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Ensure we have an anonymous session.
  Future<User> ensureSignedIn() async {
    final existing = _client.auth.currentUser;
    if (existing != null) return existing;

    final res = await _client.auth.signInAnonymously();
    final u = res.user;
    if (u == null) {
      throw StateError('Anonymous sign-in failed');
    }
    return u;
  }

  Future<void> signOut() => _client.auth.signOut();
}
