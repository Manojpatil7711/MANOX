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
      );
      _initialized = true;
      _initializationError = null;
    } catch (e, stackTrace) {
      // Never expose initialization details to users. Keep them available only
      // in debug logs so Auth failures are diagnosable without weakening
      // security or privacy controls.
      _initialized = false;
      _initializationError = e;
      debugPrint('MANOX Supabase initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
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
