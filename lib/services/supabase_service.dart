import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabase) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      // Initialization failed — in CI or in environments without keys this is expected.
    }
  }

  static SupabaseClient? get client => AppConfig.hasSupabase ? Supabase.instance.client : null;

  static bool get isInitialized => client != null;

  static Stream<AuthState>? authStateChanges() {
    if (!isInitialized) return null;
    return Supabase.instance.client.auth.onAuthStateChange;
  }
}
