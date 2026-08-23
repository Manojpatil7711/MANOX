import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../services/supabase_service.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();

  supabase.SupabaseClient? get _client => SupabaseService.client;

  static supabase.Session? get currentSession => SupabaseService.client?.auth.currentSession;

  @override
  Future<void> signIn(String email, String password) async {
    final client = _client;
    if (client == null) throw AuthException('Authentication service not configured.');
    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      if (res.session == null) throw AuthException('Invalid credentials');
    } on supabase.AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String surname,
    required String mobile,
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) throw AuthException('Authentication service not configured.');
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'surname': surname.trim(),
          'mobile': mobile.trim(),
        },
      );
      if (res.user == null) throw AuthException('Unable to create account');
    } on supabase.AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try { await client.auth.signOut(); } catch (_) {}
  }

  @override
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) throw AuthException('Authentication service not configured.');
    try {
      await client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  String _mapError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) return 'Invalid email or password.';
    if (msg.contains('already registered') || msg.contains('user already exists')) return 'Email already registered.';
    if (msg.contains('email') && msg.contains('confirm')) return 'Please confirm your email before signing in.';
    if (msg.contains('password')) return 'Password is not acceptable.';
    return 'Authentication error. Please try again.';
  }
}
