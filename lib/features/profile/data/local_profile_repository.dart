import '../domain/profile_repository.dart';
import 'demo_profile.dart';

class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository();

  @override
  Future<ProfileData> fetchProfile() async {
    // Simulate immediate local fetch
    return demoProfile;
  }

  @override
  Future<List<String>> fetchPostIds() async {
    return demoProfile.postIds;
  }
}
