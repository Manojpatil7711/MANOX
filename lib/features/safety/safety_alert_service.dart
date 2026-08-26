import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service.dart';

class SafetyAlertService {
  static final _client = SupabaseService.client;

  static Future<bool> isFemaleProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;
    final row = await client.from('profiles').select('id, gender').eq('user_id', user.id).maybeSingle();
    return row != null && (row['gender']?.toString().toLowerCase() == 'female');
  }

  static Future<Position> _location() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const SafetyAlertException('Location services are turned off.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const SafetyAlertException('Location permission is required for an alert.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const SafetyAlertException('Location permission is blocked. Enable it in Android settings.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static Future<void> updatePresence() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    final profile = await client.from('profiles').select('id').eq('user_id', user.id).maybeSingle();
    if (profile == null) return;
    final position = await _location();
    await client.from('safety_presence').upsert({
      'profile_id': profile['id'],
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<String> sendAlert({required int escalation}) async {
    if (escalation != 1 && escalation != 2) {
      throw const SafetyAlertException('Invalid alert escalation.');
    }
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const SafetyAlertException('Please sign in before using Safety Alert.');
    }
    final profile = await client.from('profiles').select('id, gender').eq('user_id', user.id).maybeSingle();
    if (profile == null || profile['gender']?.toString().toLowerCase() != 'female') {
      throw const SafetyAlertException('Safety Alert is available only to profiles set to Female.');
    }
    final position = await _location();
    final result = await client.from('safety_alerts').insert({
      'source_profile_id': profile['id'],
      'escalation': escalation,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'status': 'active',
    }).select('id').single();
    await client.from('safety_presence').upsert({
      'profile_id': profile['id'],
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return result['id'].toString();
  }
}

class SafetyAlertException implements Exception {
  final String message;
  const SafetyAlertException(this.message);
  @override
  String toString() => message;
}
