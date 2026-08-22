class ProfileData {
  final String id;
  final String displayName;
  final String handle;
  final String bio;
  final bool isCreator;
  final int followers;
  final int following;
  final List<String> postIds;

  const ProfileData({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.isCreator,
    required this.followers,
    required this.following,
    required this.postIds,
  });
}

const demoProfile = ProfileData(
  id: 'u1',
  displayName: 'Jordan Lee',
  handle: '@jordan',
  bio: 'Creator, builder, and story-teller. Sharing my journey with the world.',
  isCreator: true,
  followers: 1240,
  following: 312,
  postIds: ['p1', 'p2'],
);
