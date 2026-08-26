import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class ManoxSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final bool profile;
  const ManoxSearchResult({required this.id, required this.title, required this.subtitle, required this.profile});
}

class ManoxSearchService {
  SupabaseClient? get _client => SupabaseService.client;
  Future<List<ManoxSearchResult>> search(String rawQuery) async {
    final client = _client;
    if (client == null) throw StateError('MANOX search service is unavailable.');
    final q = rawQuery.trim();
    if (q.length < 2) return const [];
    final pattern = '%${q.replaceAll('%', '').replaceAll('_', '')}%';
    final results = <ManoxSearchResult>[];
    final profiles = await client.from('profiles').select('id, username, display_name, profession, country_code').or('username.ilike.$pattern,display_name.ilike.$pattern').limit(20);
    for (final row in (profiles as List)) {
      final name = (row['display_name'] as String?)?.trim();
      final username = (row['username'] as String?)?.trim();
      final profession = (row['profession'] as String?)?.trim();
      results.add(ManoxSearchResult(id: row['id'] as String, title: name?.isNotEmpty == true ? name! : '@${username ?? 'user'}', subtitle: profession?.isNotEmpty == true ? profession! : '@${username ?? 'user'}', profile: true));
    }
    final posts = await client.from('contents').select('id, description, content_type').eq('status', 'published').eq('visibility', 'public').ilike('description', pattern).order('created_at', ascending: false).limit(30);
    for (final row in (posts as List)) {
      final description = ((row['description'] as String?) ?? '').trim();
      results.add(ManoxSearchResult(id: row['id'] as String, title: description.isEmpty ? 'MANOX ${row['content_type'] ?? 'content'}' : description, subtitle: 'Content', profile: false));
    }
    return results;
  }
}
