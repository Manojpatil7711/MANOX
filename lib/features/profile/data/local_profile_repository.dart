import '../domain/profile_repository.dart';
import 'demo_profile.dart';

class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository();
  @override Future<ProfileData> fetchProfile() async => demoProfile;
  @override Future<ProfileData> fetchProfileByUserId(String userId) async => demoProfile;
  @override Future<List<String>> fetchPostIds() async => demoProfile.postIds;
  @override
  Future<ProfileData> updateProfile({required String displayName, required String username, required String bio, String? avatarPath, String? countryCode, String? gender, String? profession, DateTime? dateOfBirth}) async {
    return demoProfile.copyWith(displayName: displayName, handle: '@${username.replaceFirst(RegExp(r'^@+'), '')}', bio: bio, avatarUrl: avatarPath ?? demoProfile.avatarUrl, countryCode: countryCode, gender: gender, profession: profession, dateOfBirth: dateOfBirth);
  }
  @override Future<String?> uploadAvatar(List<int> bytes, String extension, String? mimeType) async => null;
}
