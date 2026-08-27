import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/supabase_service.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MANOX uses an edge-to-edge layout so the app makes full use of modern
  // phone displays while keeping system gesture/navigation areas safe.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase only when SUPABASE_URL and SUPABASE_ANON_KEY are provided via --dart-define
  if (AppConfig.hasSupabase) {
    await SupabaseService.initialize();
  }

  runApp(const ManoxApp());
}
