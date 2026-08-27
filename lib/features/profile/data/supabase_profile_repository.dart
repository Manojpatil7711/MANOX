import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/profile_repository.dart';
import 'demo_profile.dart';

class SupabaseProfileRepository implements ProfileRepository {
  static const _profileColumns = 'id,username,display_name,avatar_url,bio,country_code,gender,profession,is_creator,skills,creator_category,other_link';

  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) throw StateError('MANOX backend is not configured.');
    return client;
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Please sign in first.');
    return id;
  }

  Future<ProfileData> _profileFromRow(Map<String, dynamic> row, {DateTime? privateDob}) async {
    final id = row['id'] as String;
    List<String> postIds = <String>[];
    try {
      final rows = await _client
          .from('contents')
          .select('id')
          .eq('owner_user_id', id)
          .eq('status', 'published')
          .order('created_at', ascending: false);
      postIds = (rows as List).map((e) => e['id'] as String).toList();
    } catch (_) {
      // Profile must still render when content RLS/data is temporarily unavailable.
    }

    final rawSkills = row['skills'];
    final skills = rawSkills is List
        ? rawSkills.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).take(12).toList()
        : <String>[];
    final username = (row['username'] as String?)?.trim() ?? 'user';
    final rawLink = (row['other_link'] as String?)?.trim();

    return ProfileData(
      id: id,
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'MANOX User',
      handle: '@${username.replaceFirst(RegExp(r'^@+'), '')}',
      bio: (row['bio'] as String?) ?? '',
      isCreator: row['is_creator'] as bool? ?? false,
      followers: 0,
      following: 0,
      postIds: postIds,
      avatarUrl: await _resolveAvatar(row['avatar_url'] as String?),
      countryCode: row['country_code'] as String?,
      gender: row['gender'] as String?,
      profession: row['profession'] as String?,
      dateOfBirth: privateDob,
      skills: skills,
      creatorCategory: row['creator_category'] as String?,
      otherLink: rawLink?.isEmpty == true ? null : rawLink,
    );
  }

  Future<DateTime?> _privateDob(String profileId) async {
    try {
      final row = await _client
          .from('profile_private_details')
          .select('date_of_birth')
          .eq('profile_id', profileId)
          .maybeSingle();
      final raw = row?['date_of_birth'];
      return raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<ProfileData> _fetchProfileRow(String userId, {required bool includePrivateDob}) async {
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', userId)
        .maybeSingle();
    if (row == null) throw StateError('Profile not found.');
    return _profileFromRow(
      Map<String, dynamic>.from(row),
      privateDob: includePrivateDob ? await _privateDob(row['id'] as String) : null,
    );
  }

  Future<void> _ensureProfile(String userId) async {
    final existing = await _client.from('profiles').select('id').eq('id', userId).maybeSingle();
    if (existing != null) return;

    final email = _client.auth.currentUser?.email?.split('@').first.trim() ?? '';
    final base = email.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '').toLowerCase();
    final username = '${base.isEmpty ? 'user' : base}_${userId.substring(0, 8)}';
    final displayName = email.isEmpty ? 'MANOX User' : email;

    await _client.from('profiles').insert({
      'id': userId,
      'username': username,
      'display_name': displayName,
    });
  }

  @override
  Future<ProfileData> fetchProfile() async {
    final userId = _userId;
    try {
      return await _fetchProfileRow(userId, includePrivateDob: true);
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST116') rethrow;
      await _ensureProfile(userId);
      return _fetchProfileRow(userId, includePrivateDob: true);
    }
  }

  @override
  Future<ProfileData> fetchProfileByUserId(String userId) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) throw StateError('Profile user id is empty.');
    return _fetchProfileRow(cleanId, includePrivateDob: false);
  }

  Future<String?> _resolveAvatar(String? value) async {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    try {
      return await _client.storage.from('manox-media').createSignedUrl(value, 60 * 60 * 24 * 30);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> fetchPostIds() async {
    try {
      final rows = await _client
          .from('contents')
          .select('id')
          .eq('owner_user_id', _userId)
          .eq('status', 'published')
          .order('created_at', ascending: false);
      return (rows as List).map((e) => e['id'] as String).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<ProfileData> updateProfileExtended({
    required String displayName,
    required String username,
    required String bio,
    String? avatarPath,
    String? countryCode,
    String? gender,
    String? profession,
    DateTime? dateOfBirth,
    List<String> skills = const [],
    String? creatorCategory,
    String? otherLink,
  }) async {
    final cleanUsername = username.replaceFirst(RegExp(r'^@+'), '').trim();
    if (cleanUsername.isEmpty) throw StateError('Username cannot be empty.');

    final cleanLink = otherLink?.trim();
    if (cleanLink != null && cleanLink.isNotEmpty) {
      final uri = Uri.tryParse(cleanLink);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        throw StateError('Other link must be a valid http(s) URL.');
      }
    }

    final cleanSkills = skills.map((e) => e.trim()).where((e) => e.isNotEmpty).take(12).toList();
    final values = <String, dynamic>{
      'display_name': displayName.trim().isEmpty ? 'MANOX User' : displayName.trim(),
      'username': cleanUsername,
      'bio': bio.trim(),
      if (avatarPath != null) 'avatar_url': avatarPath,
      if (countryCode != null) 'country_code': countryCode.trim().toUpperCase(),
      if (gender != null) 'gender': gender,
      if (profession != null) 'profession': profession.trim(),
      'skills': cleanSkills,
      'creator_category': creatorCategory,
      'other_link': cleanLink?.isEmpty == true ? null : cleanLink,
    };

    await _ensureProfile(_userId);
    await _client.from('profiles').update(values).eq('id', _userId);

    if (dateOfBirth != null) {
      await _client.from('profile_private_details').upsert({
        'profile_id': _userId,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'profile_id');
    }
    return fetchProfile();
  }

  @override
  Future<ProfileData> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    String? avatarPath,
    String? countryCode,
    String? gender,
    String? profession,
    DateTime? dateOfBirth,
  }) => updateProfileExtended(
        displayName: displayName,
        username: username,
        bio: bio,
        avatarPath: avatarPath,
        countryCode: countryCode,
        gender: gender,
        profession: profession,
        dateOfBirth: dateOfBirth,
      );

  @override
  Future<String?> uploadAvatar(List<int> bytes, String extension, String? mimeType) async {
    final path = '$_userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from('manox-media').uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: mimeType, upsert: true, cacheControl: '3600'),
    );
    return path;
  }
}
