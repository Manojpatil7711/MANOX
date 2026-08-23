import '../data/demo_profile.dart';

abstract class ProfileRepository {
  Future<ProfileData> fetchProfile();
  Future<List<String>> fetchPostIds();
}
