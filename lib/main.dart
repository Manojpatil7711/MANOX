import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase only when SUPABASE_URL and SUPABASE_ANON_KEY are provided via --dart-define
  if (AppConfig.hasSupabase) {
    await SupabaseService.initialize();
  }

  runApp(const ManoxApp());
}
