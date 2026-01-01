// controllers/memory_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/Model/threadModel.dart';

class MemoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var memories = <MemoryItem>[].obs;
  var isLoading = true.obs;
  var selectedTab = 0.obs; // 0 = Timeline, 1 = By Journey

  @override
  void onInit() {
    super.onInit();
    fetchMemories();
  }
  
  // Add this to MemoryController class
var selectedFriendFilter = Rxn<UserModel>(); // null = show all

// Add method to filter memories by friend
List<MemoryItem> get filteredMemories {
  if (selectedFriendFilter.value == null) {
    return memories;
  }

  final friendId = selectedFriendFilter.value!.id;

  return memories.where((memory) {
    // We need to know which users are in this thread
    // We'll fetch thread members later, but for now, assume we add members list
    // → Better: Store members in MemoryItem when fetching
    return memory.sharedWith.contains(friendId);
  }).toList();
}

// Update fetchMemories to include sharedWith list
Future<void> fetchMemories() async {
  try {
    isLoading(true);
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      memories.clear();
      return;
    }

    final threadsSnapshot = await _firestore
        .collection('threads')
        .where('members', arrayContains: userId)
        .get();

    List<MemoryItem> allMemories = [];

    for (var threadDoc in threadsSnapshot.docs) {
      final threadId = threadDoc.id;
      final threadName = threadDoc['name'] ?? 'Untitled Journey';
      final threadType = threadDoc['type'] ?? 'solo';

      // Get members of this thread
      final List<String> threadMembers = List<String>.from(threadDoc['members'] ?? []);

      final activitiesSnapshot = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('Activities')
          .where('isMemory', isEqualTo: true)
          .get();

      for (var actDoc in activitiesSnapshot.docs) {
        final data = actDoc.data();

        final List<String> imagesURL =
            (data['imagesURL'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];

        final String coverImage = imagesURL.isNotEmpty
            ? imagesURL.first
            : 'https://via.placeholder.com/300x300/EEEEEE/999999?text=No+Photo';

        // Remove current user, keep others
        final List<String> sharedWith = threadMembers.where((id) => id != userId).toList();

        allMemories.add(
          MemoryItem(
            id: actDoc.id,
            threadId: threadId,
            threadName: threadName,
            threadType: threadType,
            activityName: data['name'] ?? 'Memory',
            memoryDetails: data['memoryDetails'] ?? '',
            imagesURL: imagesURL,
            coverImageUrl: coverImage,
            completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
            imagesCount: imagesURL.length,
            sharedWith: sharedWith, // Add this!
          ),
        );
      }
    }

    allMemories.sort((a, b) => (b.completedAt ?? DateTime.now())
        .compareTo(a.completedAt ?? DateTime.now()));

    memories.assignAll(allMemories);
  } catch (e) {
    print("Error: $e");
    Get.snackbar("Error", "Failed to load memories",backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,);
  } finally {
    isLoading(false);
  }
}

  // Optional: Refresh manually
  void refreshMemories() => fetchMemories();
}

// Updated MemoryItem with List<String> for images
class MemoryItem {
  final String id;
  final String threadId;
  final String threadName;
  final String threadType;
  final String activityName;
  final String memoryDetails;
  final List<String> imagesURL; // Full list of image URLs
  final String coverImageUrl; // First image for grid preview
  final DateTime? completedAt;
  final int imagesCount;
  // Add this field
final List<String> sharedWith; // user IDs this memory was shared with


  MemoryItem({
    required this.id,
    required this.threadId,
    required this.threadName,
    required this.threadType,
    required this.activityName,
    required this.memoryDetails,
    required this.imagesURL,
    required this.coverImageUrl,
    this.completedAt,
    required this.imagesCount,
    required this.sharedWith,
  });

  // Helper: Check if has multiple photos
  bool get hasMultiplePhotos => imagesCount > 1;

  // Helper: Get all images except the first (for overlay indicator)
  List<String> get additionalImages =>
      imagesURL.length > 1 ? imagesURL.skip(1).toList() : [];
}
