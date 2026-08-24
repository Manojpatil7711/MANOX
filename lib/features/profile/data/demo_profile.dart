class ProfileData {
  final String id;
  final String displayName;
  final String handle;
  final String bio;
  final bool isCreator;
  final int followers;
  final int following;
  final List<String> postIds;
  final String? avatarUrl;

  const ProfileData({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.isCreator,
    required this.followers,
    required this.following,
    required this.postIds,
    this.avatarUrl,
  });

  ProfileData copyWith({
    String? id,
    String? displayName,
    String? handle,
    String? bio,
    bool? isCreator,
    int? followers,
    int? following,
    List<String>? postIds,
    String? avatarUrl,
  }) {
    return ProfileData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      isCreator: isCreator ?? this.isCreator,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      postIds: postIds ?? this.postIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
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
