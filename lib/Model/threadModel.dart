import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_read_thread/Model/activityModel.dart';

// class Activity {
//   final String id;
//   final String name;
//   final String activityDetails;
//   final List<String> assignTo;
//   final Timestamp? completedAt;
//   final String? completedBy;
//   final String createdBy;
//   final List<String> imagesURL;
//   final bool isMemory;
//   final String memoryDetails;

//   final String status;

//   Activity({
//     required this.id,
//     required this.name,
//     required this.activityDetails,
//     required this.assignTo,
//     this.completedAt,
//     this.completedBy,
//     required this.createdBy,
//     required this.imagesURL,
//     required this.isMemory,
//     required this.memoryDetails,

//     required this.status,
//   });

//   factory Activity.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return Activity(
//       id: doc.id,
//       name: data['name'] ?? '',
//       activityDetails: data['activityDetails'] ?? '',
//       assignTo: List<String>.from(data['assignTo'] ?? []),
//       completedAt: data['completedAt'],
//       completedBy: data['completedBy'],
//       createdBy: data['createdBy'] ?? '',
//       imagesURL: List<String>.from(data['imagesURL'] ?? []),
//       isMemory: data['isMemory'] ?? false,
//       memoryDetails: data['memoryDetails'] ?? '',

//       status: data['status'] ?? 'pending',
//     );
//   }

//   bool get isCompleted => status == 'completed';
// }

class Thread {
  final String id;
  final int completedActivities;
  final Timestamp createdAt;
  final List<String> members;
  final String name;
  final String description;

  final int progress;
  final int totalActivities;
  final String type;
  final List<Activity> activities;

  final String createdBy; // ✅ NEW FIELD

  Thread({
    required this.id,
    required this.completedActivities,
    required this.createdAt,
    required this.members,
    required this.name,
    required this.description,

    required this.progress,
    required this.totalActivities,
    required this.type,
    required this.createdBy, // ✅ REQUIRED
    this.activities = const [],
  });

  factory Thread.fromFirestore(
    DocumentSnapshot doc, {
    List<Activity>? activities,
  }) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Thread(
      id: doc.id,
      completedActivities: data['completedActivities'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      members: List<String>.from(data['members'] ?? []),
      name: data['name'] ?? 'Untitled Journey',
      description: data['description']?.toString() ?? '',

      progress: data['progress'] ?? 0,
      totalActivities: data['totalActivities'] ?? 0,
      type: data['type'] ?? 'solo',
      createdBy: data['createdBy'] ?? '', // ✅ ADDED with fallback
      activities: activities ?? [],
    );
  }

  double get progressPercentage {
    if (totalActivities == 0) return 0.0;
    return (completedActivities / totalActivities) * 100;
  }

  bool get isSolo => type == 'solo';
  int get memberCount => members.length;
}
