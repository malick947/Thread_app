import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? username;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.username,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      username: data['username'],
    );
  }

  // Get initials from name (first letter of first and last name)
  String get initials {
    if (name.isEmpty) return '??';

    List<String> nameParts = name.trim().split(' ');

    if (nameParts.length == 1) {
      // Single name - take first two letters
      return nameParts[0]
          .substring(0, nameParts[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    } else {
      // Multiple names - take first letter of first and last name
      String firstInitial = nameParts.first[0];
      String lastInitial = nameParts.last[0];
      return (firstInitial + lastInitial).toUpperCase();
    }
  }

  // Get color based on name (for consistent avatar colors)
  int get avatarColorIndex {
    return name.hashCode % 10;
  }
}
