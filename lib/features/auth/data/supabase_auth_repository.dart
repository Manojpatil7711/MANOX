import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:url_launcher/url_launcher.dart';
import '../../../services/supabase_service.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();
  supabase.SupabaseClient? get _client => SupabaseService.client;
  static supabase.Session? get currentSession => SupabaseService.client?.auth.currentSession;
  @override bool get hasSession => currentSession != null;

  Future<supabase.SupabaseClient> _authClient() async {
    try { return await SupabaseService.ensureInitialized(); }
    on StateError { throw AuthException(_serviceUnavailableMessage); }
  }

  @override
  Future<void> signIn(String email, String password) async {
    final client = await _authClient();
    try {
      final res = await client.auth.signInWithPassword(email: email.trim(), password: password);
      if (res.session == null) throw AuthException('Invalid credentials');
    } on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  @override
  Future<void> signUp({required String firstName, required String surname, required String mobile, required String email, required String password}) async {
    final client = await _authClient();
    try {
      final res = await client.auth.signUp(
        email: email.trim(), password: password,
        emailRedirectTo: 'io.manox.app://login-callback/',
        data: {'first_name': firstName.trim(), 'surname': surname.trim(), 'mobile': mobile.trim()},
      );
      if (res.user == null) throw AuthException('Unable to create account');
    } on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    final client = await _authClient();
    try {
      await client.auth.signInWithOtp(email: email.trim(), emailRedirectTo: 'io.manox.app://login-callback/');
    } on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  @override
  Future<void> verifyEmailOtp(String email, String token) async {
    final client = await _authClient();
    try {
      final res = await client.auth.verifyOTP(email: email.trim(), token: token.trim(), type: supabase.OtpType.email);
      if (res.session == null) throw AuthException('The code is invalid or expired.');
    } on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  @override
  Future<void> signInWithGoogle() async {
    final client = await _authClient();
    try {
      await client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'io.manox.app://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try { await client.auth.signOut(); } catch (_) {}
  }

  @override
  Future<void> resetPassword(String email) async {
    final client = await _authClient();
    try { await client.auth.resetPasswordForEmail(email.trim(), redirectTo: 'io.manox.app://login-callback/'); }
    on supabase.AuthException catch (e) { throw AuthException(_mapError(e)); }
    catch (e) { if (e is AuthException) rethrow; throw AuthException(_mapError(e)); }
  }

  static const String _serviceUnavailableMessage = 'Authentication service is unavailable. Please try again later.';

  String _mapError(Object e) {
    if (e is supabase.AuthException) {
      final message = e.message.trim();
      final lower = message.toLowerCase();
      if (lower.contains('invalid login') || lower.contains('invalid credentials')) return 'Invalid email or password.';
      if (lower.contains('already registered') || lower.contains('user already exists')) return 'This email is already registered. Try signing in.';
      if (lower.contains('email') && lower.contains('confirm')) return 'Please confirm your email, then sign in.';
      if (lower.contains('otp') || lower.contains('token') || lower.contains('expired')) return 'That code is invalid or expired. Request a new code.';
      if (lower.contains('rate limit') || lower.contains('too many requests')) return 'Too many attempts. Please wait a moment and try again.';
      return message.isEmpty ? 'Authentication error. Please try again.' : message;
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connection')) return 'Network connection failed. Please check your internet and try again.';
    return 'Authentication error. Please try again.';
  }
}
