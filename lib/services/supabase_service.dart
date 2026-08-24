import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static Object? _initializationError;
  static StreamSubscription<Uri>? _deepLinkSubscription;

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabase) return;
    if (_initialized) return;

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
      _initializationError = null;
      _startAuthDeepLinkFallback();
    } catch (e, stackTrace) {
      _initialized = false;
      _initializationError = e;
      debugPrint('MANOX Supabase initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Supabase Flutter normally handles auth deep links internally. This
  /// explicit listener is a safe fallback for Android custom-scheme callbacks
  /// so a PKCE `code` is exchanged even if the platform callback arrives
  /// before the SDK's internal listener is ready.
  static void _startAuthDeepLinkFallback() {
    if (kIsWeb || _deepLinkSubscription != null) return;

    final appLinks = AppLinks();
    _deepLinkSubscription = appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme != 'io.manox.app' || uri.host != 'login-callback') return;

      // Use a differently named local variable so it does not shadow the
      // SupabaseService.client getter.
      final supabaseClient = client;
      if (supabaseClient == null ||
          supabaseClient.auth.currentSession != null) {
        return;
      }

      final error = uri.queryParameters['error'];
      if (error != null) {
        debugPrint('MANOX OAuth callback error: $error');
        return;
      }

      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) return;

      try {
        await supabaseClient.auth.exchangeCodeForSession(code);
        debugPrint('MANOX OAuth callback: PKCE session established.');
      } catch (e, stackTrace) {
        debugPrint('MANOX OAuth callback session exchange failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  static Future<SupabaseClient> ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }

    final supabaseClient = client;
    if (supabaseClient == null) {
      throw StateError(
        _initializationError == null
            ? 'Supabase authentication service is unavailable.'
            : 'Supabase initialization failed.',
      );
    }
    return supabaseClient;
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  static bool get isInitialized => _initialized;
  static Object? get initializationError => _initializationError;

  static Stream<AuthState>? authStateChanges() {
    final supabaseClient = client;
    if (supabaseClient == null) return null;
    return supabaseClient.auth.onAuthStateChange;
  }
}
