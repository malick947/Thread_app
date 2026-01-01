import 'package:cloud_firestore/cloud_firestore.dart';

class SnapModel {
  final String id;
  final String userId;
  final String username;
  final String photoUrl;
  final DateTime createdAt;

  SnapModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.createdAt,
  });

  factory SnapModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SnapModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      username: data['username'] ?? 'Unknown',
      photoUrl: data['photo_url'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
