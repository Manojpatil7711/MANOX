import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static Object? _initializationError;

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
    } catch (e, stackTrace) {
      _initialized = false;
      _initializationError = e;
      debugPrint('MANOX Supabase initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Ensures Auth calls do not fail just because the first initialization
  /// attempt was interrupted or temporarily failed.
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
