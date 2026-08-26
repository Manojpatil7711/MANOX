import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../domain/profile_repository.dart';
import 'demo_profile.dart';

class SupabaseProfileRepository implements ProfileRepository {
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

  Future<ProfileData> _profileFromRow(Map<String, dynamic> row) async {
    final id = (row['id'] ?? row['user_id']) as String;
    List<String> postIds = <String>[];
    try {
      final rows = await _client.from('contents').select('id').eq('owner_user_id', id).eq('status', 'published').order('created_at', ascending: false);
      postIds = (rows as List).map((e) => e['id'] as String).toList();
    } catch (_) {}
    final username = (row['username'] as String?)?.trim() ?? 'user';
    return ProfileData(
      id: id,
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true ? row['display_name'] as String : 'MANOX User',
      handle: '@${username.replaceFirst(RegExp(r'^@+'), '')}',
      bio: (row['bio'] as String?) ?? '',
      isCreator: row['is_creator'] as bool? ?? false,
      followers: 0,
      following: 0,
      postIds: postIds,
      avatarUrl: await _resolveAvatar(row['avatar_url'] as String?),
    );
  }

  @override
  Future<ProfileData> fetchProfile() async {
    final userId = _userId;
    Map<String, dynamic>? row;
    try {
      row = await _client.from('profiles').select('id, user_id, username, display_name, avatar_url, bio, is_creator').eq('user_id', userId).maybeSingle();
    } catch (_) {
      row = await _client.from('profiles').select('id, username, display_name, avatar_url, bio').eq('id', userId).maybeSingle();
    }
    if (row == null) {
      final emailName = _client.auth.currentUser?.email?.split('@').first ?? 'user';
      try {
        await _client.from('profiles').insert({'user_id': userId, 'username': emailName, 'display_name': emailName});
      } catch (_) {
        await _client.from('profiles').upsert({'id': userId, 'username': emailName, 'display_name': emailName});
      }
      row = await _client.from('profiles').select('id, user_id, username, display_name, avatar_url, bio, is_creator').eq('id', userId).maybeSingle();
    }
    if (row == null) throw StateError('Profile could not be created.');
    return _profileFromRow(row);
  }

  @override
  Future<ProfileData> fetchProfileByUserId(String userId) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) throw StateError('Invalid profile id.');
    Map<String, dynamic>? row;
    try {
      row = await _client.from('profiles').select('id, user_id, username, display_name, avatar_url, bio, is_creator').eq('user_id', cleanId).maybeSingle();
    } catch (_) {
      row = await _client.from('profiles').select('id, username, display_name, avatar_url, bio').eq('id', cleanId).maybeSingle();
    }
    if (row == null) throw StateError('Profile not found.');
    return _profileFromRow(row);
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
      final rows = await _client.from('contents').select('id').eq('owner_user_id', _userId).eq('status', 'published').order('created_at', ascending: false);
      return (rows as List).map((e) => e['id'] as String).toList();
    } catch (_) {
      return <String>[];
    }
  }

  @override
  Future<ProfileData> updateProfile({required String displayName, required String username, required String bio, String? avatarPath, String? gender}) async {
    final cleanUsername = username.replaceFirst(RegExp(r'^@+'), '').trim();
    if (cleanUsername.isEmpty) throw StateError('Username cannot be empty.');
    final values = <String, dynamic>{
      'display_name': displayName.trim(),
      'username': cleanUsername,
      'bio': bio.trim(),
      if (avatarPath != null) 'avatar_url': avatarPath,
      if (gender != null) 'gender': gender,
    };
    try {
      await _client.from('profiles').update(values).eq('user_id', _userId);
    } catch (_) {
      await _client.from('profiles').update(values).eq('id', _userId);
    }
    return fetchProfile();
  }

  @override
  Future<String?> uploadAvatar(List<int> bytes, String extension, String? mimeType) async {
    final path = '$_userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from('manox-media').uploadBinary(path, Uint8List.fromList(bytes), fileOptions: FileOptions(contentType: mimeType, upsert: true, cacheControl: '3600'));
    return path;
  }
}
