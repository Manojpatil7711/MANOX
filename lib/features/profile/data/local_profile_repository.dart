import '../domain/profile_repository.dart';
import 'demo_profile.dart';

class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository();
  @override Future<ProfileData> fetchProfile() async => demoProfile;
  @override Future<ProfileData> fetchProfileByUserId(String userId) async => demoProfile;
  @override Future<List<String>> fetchPostIds() async => demoProfile.postIds;
  @override
  Future<ProfileData> updateProfile({required String displayName, required String username, required String bio, String? avatarPath, String? gender}) async => ProfileData(id: demoProfile.id, displayName: displayName, handle: '@${username.replaceFirst(RegExp(r'^@+'), '')}', bio: bio, isCreator: demoProfile.isCreator, followers: demoProfile.followers, following: demoProfile.following, postIds: demoProfile.postIds, avatarUrl: avatarPath);
  @override Future<String?> uploadAvatar(List<int> bytes, String extension, String? mimeType) async => null;
}
