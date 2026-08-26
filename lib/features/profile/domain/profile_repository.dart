import '../data/demo_profile.dart';

abstract class ProfileRepository {
  Future<ProfileData> fetchProfile();
  Future<ProfileData> fetchProfileByUserId(String userId);
  Future<List<String>> fetchPostIds();
  Future<ProfileData> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    String? avatarPath,
    String? countryCode,
    String? gender,
    String? profession,
    DateTime? dateOfBirth,
  });
  Future<String?> uploadAvatar(List<int> bytes, String extension, String? mimeType);
}
