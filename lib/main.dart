import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/supabase_service.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // MANOX uses an immersive full-screen mobile experience.
    // These two APIs are synchronous in the Flutter SDK used by CI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
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
