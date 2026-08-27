import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/supabase_service.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep startup resilient: platform configuration or an optional backend
  // must never prevent the Flutter shell from starting.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('MANOX Flutter error: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  try {
    // MANOX is designed as a full-screen mobile experience (similar to
    // modern social/video apps). System bars stay hidden during normal use;
    // Android/iOS can reveal them temporarily with the system gesture.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, stackTrace) {
    debugPrint('MANOX system UI setup failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Initialize Supabase only when SUPABASE_URL and SUPABASE_ANON_KEY are
  // provided via --dart-define. SupabaseService handles its own failures so
  // the app can still open when the backend is temporarily unavailable.
  if (AppConfig.hasSupabase) {
    try {
      await SupabaseService.initialize();
    } catch (e, stackTrace) {
      debugPrint('MANOX Supabase startup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ManoxApp());
}
