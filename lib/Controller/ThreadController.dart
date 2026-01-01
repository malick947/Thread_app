import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/Model/activityModel.dart';
import 'package:the_read_thread/Model/threadModel.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';

class ThreadController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> addActivity({
    required String threadId,
    required String name,
    required String activityDetails,
    required List<String> assignTo,
    required String priority,
    DateTime? selectedDate,
  }) async {
    if (currentUserId == null) return;

    final threadRef = _firestore.collection('threads').doc(threadId);
    final activitiesRef = threadRef.collection('Activities');

    try {
      await _firestore.runTransaction((transaction) async {
        final newActivityRef = activitiesRef.doc();
        final activityData = {
          'name': name,
          'activityDetails': activityDetails,
          'assignTo': assignTo,
          'createdBy': currentUserId,
          'status': 'pending',
          'isMemory': false,
          'memoryDetails': '',
          'imagesURL': <String>[],
          'completedAt': null,
          'completedBy': null,
          'createdAt': FieldValue.serverTimestamp(),
          'ActivityDate': selectedDate,
          'isSpark': false, // Regular activity
        };

        transaction.set(newActivityRef, activityData);

        transaction.update(threadRef, {
          'totalActivities': FieldValue.increment(1),
        });
      });

      print("Activity added and totalActivities incremented");
    } catch (e) {
      print("Error adding activity: $e");
      rethrow;
    }
  }

  Stream<List<Thread>> getUserThreads() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('threads')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Thread> threads = [];

          for (var doc in snapshot.docs) {
            List<Activity> activities = await getThreadActivities(doc.id);
            Thread thread = Thread.fromFirestore(doc, activities: activities);
            threads.add(thread);
          }
          print("We have activities");
          return threads;
        });
  }

  Future<List<Activity>> getThreadActivities(String threadId) async {
    try {
      QuerySnapshot activitiesSnapshot = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .get();
      print("We have activities now");
      return activitiesSnapshot.docs
          .map((doc) => Activity.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  // Get spark activity details
  Future<SparkActivityModel?> getSparkActivityDetails(
    String threadId,
    String activityId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      // Check if it's a spark activity
      if (data['isSpark'] == true) {
        return SparkActivityModel.fromFirestore(data);
      }

      return null;
    } catch (e) {
      print('Error fetching spark activity: $e');
      return null;
    }
  }

  // Check if activity is a spark
  Future<bool> isSparkActivity(String threadId, String activityId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['isSpark'] == true;
    } catch (e) {
      print('Error checking spark activity: $e');
      return false;
    }
  }

  Future<Thread?> getThreadById(String threadId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('threads')
          .doc(threadId)
          .get();

      if (!doc.exists) return null;
      print("We are going to load activities");

      List<Activity> activities = await getThreadActivities(threadId);
      return Thread.fromFirestore(doc, activities: activities);
    } catch (e) {
      print('Error fetching thread: $e');
      return null;
    }
  }

  Future<void> updateThreadProgress(String threadId) async {
    try {
      List<Activity> activities = await getThreadActivities(threadId);
      int completedCount = activities.where((a) => a.isCompleted).length;
      int totalCount = activities.length;
      int progress = totalCount > 0
          ? ((completedCount / totalCount) * 100).round()
          : 0;

      await _firestore.collection('threads').doc(threadId).update({
        'completedActivities': completedCount,
        'totalActivities': totalCount,
        'progress': progress,
      });
    } catch (e) {
      print('Error updating thread progress: $e');
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      List<UserModel> users = [];

      for (String userId in userIds) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateActivityStatus(
    String threadId,
    String activityId,
    String status,
  ) async {
    try {
      // First check if it's a spark activity
      final doc = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .get();

      final data = doc.data() as Map<String, dynamic>;
      bool isSpark = data['isSpark'] ?? false;

      Map<String, dynamic> updateData = {};

      if (isSpark) {
        // For spark activities, update isCompleted field
        updateData['isCompleted'] = (status == 'completed');
        updateData['status'] = status;
      } else {
        // For regular activities, update status field
        updateData['status'] = status;
      }

      if (status == 'completed') {
        updateData['completedAt'] = Timestamp.now();
        updateData['completedBy'] = currentUserId;
      }

      await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .update(updateData);

      await updateThreadProgress(threadId);
    } catch (e) {
      print('Error updating activity status: $e');
    }
  }

  Future<void> addThread({
    required String title,
    required String description,
    required String priority,
    required bool isShared,
    required List<String> invitedMembers,
    DateTime? goalDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    List<String> members = [uid];

    if (isShared && invitedMembers.isNotEmpty) {
      members.addAll(invitedMembers);
    }

    members = members.toSet().toList();

    final String type = determineThreadType(members);

    try {
      final WriteBatch batch = _firestore.batch();

      final DocumentReference threadRef = _firestore
          .collection('threads')
          .doc();
      batch.set(threadRef, {
        'name': title,
        'description': description,
        'createdAt': Timestamp.now(),
        'goalDate': goalDate != null ? Timestamp.fromDate(goalDate) : null,
        'members': members,
        'type': type,
        'completedActivities': 0,
        'totalActivities': 0,
        'progress': 0,
        'createdBy': uid,
      });

      for (String memberId in members) {
        final DocumentReference userRef = _firestore
            .collection('users')
            .doc(memberId);
        batch.set(userRef, {
          'total_threads': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      Get.snackbar(
        "Journey Created!",
        "Added to you and ${members.length - 1} friend(s)",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error creating thread: $e");
      Get.snackbar(
        "Failed",
        "Could not create journey",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  String determineThreadType(List<String> members) {
    if (members.length <= 1) return "solo";
    if (members.length == 2) return "dual";
    return "group";
  }

  Future<List<UserModel>> loadMyFriends() async {
    try {
      final uid = currentUserId;
      if (uid == null) return [];

      QuerySnapshot snapshot = await _firestore.collection('users').get();

      List<UserModel> friends = snapshot.docs
          .where((doc) => doc.id != uid)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      print("We have friends now");

      return friends;
    } catch (e) {
      print('Error loading friends: $e');
      return [];
    }
  }

  Future<void> addToMemory({
    required String threadId,
    required String activityId,
    required String memoryDetails,
    List<String> imagesURL = const [],
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      Map<String, dynamic> updateData = {
        'isMemory': true,
        'memoryDetails': memoryDetails,
        'imagesURL': imagesURL,
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference activityRef = _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId);

      batch.update(activityRef, updateData);

      DocumentReference userRef = _firestore
          .collection('users')
          .doc(currentUser.uid);

      batch.update(userRef, {'memories_knotted': FieldValue.increment(1)});

      await batch.commit();

      print(
        "Memory saved successfully with ${imagesURL.length} image(s) & counter incremented!",
      );
    } catch (e) {
      print("Error saving memory: $e");
      rethrow;
    }
  }

  Future<void> deleteMemoryImages(List<String> imageUrls) async {
    try {
      for (String url in imageUrls) {
        final ref = FirebaseStorage.instanceFor(
          bucket: 'your-bucket-name',
        ).refFromURL(url);
        await ref.delete();
      }
      print("Images deleted successfully");
    } catch (e) {
      print("Error deleting images: $e");
    }
  }

  Stream<Thread?> getThreadStream(String threadId) {
    return _firestore.collection('threads').doc(threadId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) return null;
      final activities = await getThreadActivities(threadId);
      return Thread.fromFirestore(doc, activities: activities);
    });
  }

  Future<void> deleteThread(String threadId) async {
    try {
      final threadRef = _firestore.collection('threads').doc(threadId);

      final activitiesSnapshot = await threadRef.collection('Activities').get();

      WriteBatch batch = _firestore.batch();

      for (var doc in activitiesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(threadRef);

      await batch.commit();
      print("Thread and all activities deleted successfully.");
    } catch (e) {
      print("Error deleting thread: $e");
      rethrow;
    }
  }

  Future<void> deleteActivity(String threadId, String activityId) async {
    try {
      // Get the activity to check if it's completed
      final activityDoc = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .get();

      final activityData = activityDoc.data() as Map<String, dynamic>;
      bool isCompleted =
          activityData['status'] == 'completed' ||
          activityData['isCompleted'] == true;

      // Delete the activity
      await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .doc(activityId)
          .delete();

      // Update thread counters
      Map<String, dynamic> updates = {
        'totalActivities': FieldValue.increment(-1),
      };

      if (isCompleted) {
        updates['completedActivities'] = FieldValue.increment(-1);
      }

      await _firestore.collection('threads').doc(threadId).update(updates);
    } catch (e) {
      print("Error deleting activity: $e");
    }
  }

  Future<void> updateActivityAssignedMembers({
    required String threadId,
    required String activityId,
    required List<String> members,
  }) async {
    // Check if it's a spark activity to use correct field name
    final doc = await _firestore
        .collection('threads')
        .doc(threadId)
        .collection('Activities')
        .doc(activityId)
        .get();

    final data = doc.data() as Map<String, dynamic>;
    bool isSpark = data['isSpark'] ?? false;

    String fieldName = isSpark ? 'assignedTo' : 'assignTo';

    await _firestore
        .collection('threads')
        .doc(threadId)
        .collection('Activities')
        .doc(activityId)
        .update({fieldName: members});
  }

  Future<void> addFriendToThread(String threadId, String friendId) async {
    try {
      final doc = await _firestore.collection('threads').doc(threadId).get();
      final members = List<String>.from(doc['members']);

      if (members.contains(friendId)) {
        await _firestore.collection('threads').doc(threadId).update({
          'members': FieldValue.arrayRemove([friendId]),
        });
      } else {
        await _firestore.collection('threads').doc(threadId).update({
          'members': FieldValue.arrayUnion([friendId]),
        });
      }
    } catch (e) {
      print("Error toggling friend: $e");
      rethrow;
    }
  }
}
