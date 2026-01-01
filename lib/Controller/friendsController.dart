import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Model/UserModel.dart';

class FriendsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<UserModel> friends = <UserModel>[].obs;
  RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadMyFriends();
  }
  RxString searchQuery = ''.obs;

  void updateSearch(String value) {
    searchQuery.value = value.toLowerCase();
  }

  /*Future<List<UserModel>> getUsersForInvite() async {
    if (currentUserId == null) return [];

    try {
      // 1. Get current friends IDs
      final friendsSnap = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('myFriends')
          .get();

      final Set<String> friendIds = friendsSnap.docs.map((e) => e.id).toSet();
      friendIds.add(currentUserId!); // exclude self

      // 2. Get all users except current user and existing friends
      final usersSnap = await _firestore.collection('users').get();

      final List<UserModel> users = usersSnap.docs
          .where((doc) => !friendIds.contains(doc.id))
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return users;
    } catch (e) {
      print("Error fetching users for invite: $e");
      return [];
    }
  }*/

  // Track invitation state (to disable button after sending)
  final RxSet<String> _invitedUserIds = <String>{}.obs;

  bool isInvited(String userId) => _invitedUserIds.contains(userId);

  // New: Send friend invitation
  Future<void> becomeMyFriend(String friendId, String name) async {
    if (currentUserId == null || currentUserId == friendId) return;

    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .doc(friendId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('myFriends')
        .doc(currentUserId);

    final now = FieldValue.serverTimestamp();

    batch.set(myFriendRef, {
      'name': name,
      'createdAt': now,
      'status': 'accepted', // or 'pending' if you want approval flow
    });

    batch.set(theirFriendRef, {'createdAt': now, 'status': 'accepted'});

    try {
      await batch.commit();
      _invitedUserIds.add(friendId); // Mark as invited locally
      Get.snackbar(
        "Success",
        "Friend added!",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send invite",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  // Optional: Refresh invited state on screen reopen
  void resetInvitedState() {
    _invitedUserIds.clear();
  }

  // -----------------------------------------------------------
  // LOAD ALL USERS AS FRIENDS (EXCEPT CURRENT USER)
  // -----------------------------------------------------------
  // -----------------------------------------------------------
  // LOAD REAL FRIENDS (from users/{uid}/myFriends subcollection)
  // -----------------------------------------------------------
  Future<void> loadMyFriends() async {
    if (currentUserId == null) {
      friends.clear();
      return;
    }

    try {
      isLoading.value = true;

      // 1. Get the list of friend IDs from the current user's myFriends subcollection
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('myFriends')
          .get();

      // If the user has no friends yet
      if (friendsSnapshot.docs.isEmpty) {
        friends.assignAll([]); // clear the list
        return;
      }

      // Extract friend UIDs (they are the document IDs)
      final List<String> friendIds = friendsSnapshot.docs
          .map((doc) => doc.id) // doc.id == friend UID
          .toList();

      // 2. Fetch the actual user profiles for those IDs
      // Firestore lets us use `whereIn` (max 10 items per query)
      // → we chunk the list if there are more than 10 friends
      List<UserModel> loadedFriends = [];

      const int chunkSize = 10;
      for (int i = 0; i < friendIds.length; i += chunkSize) {
        final chunk = friendIds.sublist(
          i,
          i + chunkSize > friendIds.length ? friendIds.length : i + chunkSize,
        );

        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final chunkUsers = usersSnapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        loadedFriends.addAll(chunkUsers);
      }

      // Sort alphabetically by name (optional)
      loadedFriends.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

      friends.assignAll(loadedFriends);
      print('Loaded friends are:${loadedFriends.length}');
    } catch (e) {
      print("Error loading friends: $e");
      Get.snackbar("Error", "Failed to load friends",backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,);
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------------------------------------------
  // COUNT SHARED THREADS WITH A SPECIFIC FRIEND
  // -----------------------------------------------------------
  Future<int> getSharedThreadsCount(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return 0;

    QuerySnapshot threadsSnap = await _firestore
        .collection('threads')
        .where('members', arrayContains: uid)
        .get();

    int sharedCount = threadsSnap.docs.where((doc) {
      List members = doc['members'];
      return members.contains(friendId);
    }).length;

    return sharedCount;
  }
  // Add this method to your FriendsController class

  Future<List<UserModel>> getUsersForInvite() async {
    if (currentUserId == null) return [];

    try {
      // 1. Get current friends and pending requests
      final friendsSnap = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('myFriends')
          .get();

      final Set<String> excludeIds = friendsSnap.docs.map((e) => e.id).toSet();
      excludeIds.add(currentUserId!); // exclude self

      // 2. Get all users except current user and existing connections
      final usersSnap = await _firestore.collection('users').get();

      final List<UserModel> users = usersSnap.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      return users;
    } catch (e) {
      print("Error fetching users for invite: $e");
      return [];
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(String friendId, String friendName) async {
    if (currentUserId == null || currentUserId == friendId) return;

    final batch = _firestore.batch();

    // Add to current user's myFriends (as sender)
    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .doc(friendId);

    // Add to other user's myFriends (as receiver)
    final theirFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('myFriends')
        .doc(currentUserId);

    final now = FieldValue.serverTimestamp();

    // Current user's document
    batch.set(myFriendRef, {
      'name': friendName,
      'createdAt': now,
      'status': 'pending',
      'sender': currentUserId,
      'receiver': friendId,
    });

    // Friend's document
    batch.set(theirFriendRef, {
      'createdAt': now,
      'status': 'pending',
      'sender': currentUserId,
      'receiver': friendId,
    });

    try {
      await batch.commit();
      _invitedUserIds.add(friendId);
      Get.snackbar(
        "Success",
        "Friend request sent!",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send request",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String friendId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .doc(friendId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('myFriends')
        .doc(currentUserId);

    // Update status to accepted in both documents
    batch.update(myFriendRef, {'status': 'accepted'});
    batch.update(theirFriendRef, {'status': 'accepted'});

    try {
      await batch.commit();
      Get.snackbar(
        "Success",
        "Friend request accepted!",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to accept request",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String friendId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .doc(friendId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('myFriends')
        .doc(currentUserId);

    // Delete both documents
    batch.delete(myFriendRef);
    batch.delete(theirFriendRef);

    try {
      await batch.commit();
      Get.snackbar(
        "Rejected",
        "Friend request rejected",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to reject request",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  /// Cancel sent friend request
  Future<void> cancelFriendRequest(String friendId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    final myFriendRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .doc(friendId);

    final theirFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('myFriends')
        .doc(currentUserId);

    batch.delete(myFriendRef);
    batch.delete(theirFriendRef);

    try {
      await batch.commit();
      Get.snackbar(
        "Cancelled",
        "Friend request cancelled",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to cancel request",
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  /// Stream to get accepted friends only
  Stream<List<UserModel>> myFriendsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((friendsSnapshot) async {
          if (friendsSnapshot.docs.isEmpty) {
            return <UserModel>[];
          }

          final List<String> friendIds = friendsSnapshot.docs
              .map((doc) => doc.id)
              .toList();

          List<UserModel> loadedFriends = [];
          const int chunkSize = 10;

          for (int i = 0; i < friendIds.length; i += chunkSize) {
            final chunk = friendIds.sublist(
              i,
              i + chunkSize > friendIds.length
                  ? friendIds.length
                  : i + chunkSize,
            );

            final usersSnapshot = await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

            final chunkUsers = usersSnapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();

            loadedFriends.addAll(chunkUsers);
          }

          loadedFriends.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

          return loadedFriends;
        });
  }

  /// Stream to get pending friend requests
  Stream<List<Map<String, dynamic>>> pendingRequestsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('myFriends')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((requestsSnapshot) async {
          if (requestsSnapshot.docs.isEmpty) {
            return <Map<String, dynamic>>[];
          }

          List<Map<String, dynamic>> requests = [];

          for (var doc in requestsSnapshot.docs) {
            final data = doc.data();
            final String friendId = doc.id;
            final String sender = data['sender'] ?? '';
            final String receiver = data['receiver'] ?? '';

            // Fetch the other user's details
            final userDoc = await _firestore
                .collection('users')
                .doc(friendId)
                .get();

            if (userDoc.exists) {
              final user = UserModel.fromFirestore(userDoc);
              requests.add({
                'user': user,
                'sender': sender,
                'receiver': receiver,
                'createdAt': data['createdAt'],
              });
            }
          }

          // Sort by creation time (most recent first)
          requests.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return requests;
        });
  }

  /// Stream to get shared threads count with a specific friend
  Stream<int> sharedThreadsCountStream(String friendId) {
    final uid = currentUserId;
    if (uid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('threads')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          int count = snapshot.docs.where((doc) {
            List members = doc['members'] ?? [];
            return members.contains(friendId);
          }).length;

          return count;
        });
  }

  // -----------------------------------------------------------
  // FETCH ALL SHARED THREADS WITH FRIEND
  // -----------------------------------------------------------
  Future<List<DocumentSnapshot>> getSharedThreads(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return [];

    QuerySnapshot threadsSnap = await _firestore
        .collection('threads')
        .where('members', arrayContains: uid)
        .get();

    return threadsSnap.docs.where((doc) {
      List members = doc['members'];
      return members.contains(friendId);
    }).toList();
  }

  // -----------------------------------------------------------
  // FETCH ACTIVITIES OF A SPECIFIC THREAD
  // -----------------------------------------------------------
  Future<List<DocumentSnapshot>> getSharedActivitiesForThread(
    String threadId,
  ) async {
    QuerySnapshot aSnap = await _firestore
        .collection('threads')
        .doc(threadId)
        .collection('Activities')
        .get();

    return aSnap.docs;
  }

  // -----------------------------------------------------------
  // FETCH ALL SHARED ACTIVITIES + MEMORY IMAGES
  // -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllSharedActivities(
    String friendId,
  ) async {
    List<Map<String, dynamic>> allActivities = [];

    List<DocumentSnapshot> sharedThreads = await getSharedThreads(friendId);

    for (var thread in sharedThreads) {
      List<DocumentSnapshot> acts = await getSharedActivitiesForThread(
        thread.id,
      );

      for (var a in acts) {
        allActivities.add({
          "threadId": thread.id,
          "threadName": thread["name"],
          "activity": a.data(),
        });
      }
    }

    return allActivities;
  }
}
