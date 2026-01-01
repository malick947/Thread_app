// models/UserProfileModel.dart
class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final String about;
  final int totalThreads;
  final int memoriesKnotted;
  final int totalFriends;
  final String? photoUrl;
  final String username;

  UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.about,
    required this.totalThreads,
    required this.memoriesKnotted,
    required this.totalFriends,
    this.photoUrl,
    required this.username
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> data, String id) {
    return UserProfileModel(
      uid: id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      about: data['about'] ?? 'No bio yet',
      totalThreads: data['total_threads'] ?? 0,
      memoriesKnotted: data['memories_knotted'] ?? 0,
      totalFriends: data['total_friends'] ?? 0,
      photoUrl: data['photoUrl'],
      username: data['username']
    );
  }
}