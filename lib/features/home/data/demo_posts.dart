class HomeDemoData {
  final String id;
  final String creatorName;
  final String handle;
  final String text;
  final int likes;
  final int comments;
  final String? imagePath;
  final String mediaType;
  final bool likedByMe;
  final bool savedByMe;
  final bool isRemote;
  final String? ownerUserId;

  const HomeDemoData({
    required this.id,
    required this.creatorName,
    required this.handle,
    required this.text,
    this.likes = 0,
    this.comments = 0,
    this.imagePath,
    this.mediaType = 'post',
    this.likedByMe = false,
    this.savedByMe = false,
    this.isRemote = false,
    this.ownerUserId,
  });
}

const demoPosts = [
  HomeDemoData(id: 'p1', creatorName: 'Ava Carter', handle: '@avac', text: 'Exploring creator tools at MANOX — excited to build with makers worldwide!', likes: 12, comments: 3),
  HomeDemoData(id: 'p2', creatorName: 'Riley Kim', handle: '@rileyk', text: 'Just published my walkthrough on community growth. Feedback welcome!', likes: 8, comments: 1),
];
