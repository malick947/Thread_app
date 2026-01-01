import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/snapModel.dart';

import 'package:the_read_thread/UI/SnapPreviewScreen.dart';

class SnapsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  RxList<SnapModel> snaps = <SnapModel>[].obs;
  RxBool isLoading = false.obs;
  StreamSubscription<QuerySnapshot>? _snapsSubscription;

  String? _myTodaySnapDocId;

  @override
  void onInit() {
    super.onInit();
    // Start listening to snaps stream when controller initializes
    startSnapsStream();
  }

  @override
  void onClose() {
    // Cancel subscription when controller is disposed
    _snapsSubscription?.cancel();
    super.onClose();
  }

  // Start real-time stream for snaps
  void startSnapsStream() {
    final friendsCtrl = Get.find<FriendsController>();
    
    // Cancel any existing subscription
    _snapsSubscription?.cancel();
    
    // Watch for friends list changes to restart stream
    ever(friendsCtrl.friends, (_) {
      _restartSnapsStream();
    });
    
    // Initial stream setup
    _restartSnapsStream();
  }

  void _restartSnapsStream() {
    _snapsSubscription?.cancel();
    _setupSnapsStream();
  }

  void _setupSnapsStream() {
    try {
      final friendsCtrl = Get.find<FriendsController>();
      final currentUserId = _auth.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      // Get friend IDs
      final friendIds = friendsCtrl.friends.map((f) => f.id).toList();
      
      // Always add current user
      if (!friendIds.contains(currentUserId)) {
        friendIds.add(currentUserId);
      }
      
      if (friendIds.isEmpty) {
        snaps.clear();
        return;
      }
      
      // UTC day start and end for today
      final now = DateTime.now().toUtc();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      
      // Create stream query
      final streamQuery = _firestore
          .collection('Snaps')
          .where('user_id', whereIn: friendIds)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .orderBy('created_at', descending: true)
          .snapshots();
      
      // Listen to stream
      _snapsSubscription = streamQuery.listen(
        (QuerySnapshot snapshot) {
          _processSnapsSnapshot(snapshot, currentUserId);
        },
        onError: (error) {
          print("Snaps stream error: $error");
          isLoading.value = false;
        },
      );
      
      isLoading.value = true;
    } catch (e) {
      print("Error setting up snaps stream: $e");
      isLoading.value = false;
    }
  }

  void _processSnapsSnapshot(QuerySnapshot snapshot, String currentUserId) {
    try {
      snaps.value = snapshot.docs.map((doc) {
        return SnapModel.fromFirestore(doc);
      }).toList();
      
      // Track my snap document ID
      _myTodaySnapDocId = snapshot.docs
          .firstWhereOrNull((doc) => doc['user_id'] == currentUserId)
          ?.id;
          
      print("My snap doc ID: $_myTodaySnapDocId");
      
      isLoading.value = false;
    } catch (e) {
      print("Error processing snapshot: $e");
      isLoading.value = false;
    }
  }

  // Manual refresh if needed
  // Manual refresh if needed
Future<void> refreshSnaps() async {
  // Simply restart the stream
  _restartSnapsStream();
  // Return a completed future
  return;
}

  // Take new snap
  Future<void> addMySnap() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    Get.to(
      () => SnapPreviewAndUpload(
        imagePath: image.path,
        onUpload: uploadOrUpdateMySnap,
        existingSnapId: _myTodaySnapDocId,
      ),
    );
  }

  Future<void> uploadOrUpdateMySnap(String imagePath) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child('snaps/$fileName');
      await ref.putFile(File(imagePath));

      final imageUrl = await ref.getDownloadURL();

      if (_myTodaySnapDocId == null) {
        // Create new
        await _firestore.collection('Snaps').add({
          'user_id': user.uid,
          'username': user.displayName ?? "User",
          'photo_url': imageUrl,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing
        await _firestore.collection('Snaps').doc(_myTodaySnapDocId).update({
          'photo_url': imageUrl,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      Get.back(); // loading
      Get.back(); // preview
      
      // No need to manually call loadAllFriendsSnaps() - stream will update automatically
    } catch (e) {
      Get.back();
      print("Snap upload error: $e");
    }
  }

  Future<void> pickSnap({required bool fromGallery}) async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    Get.to(
      () => SnapPreviewAndUpload(
        imagePath: image.path,
        onUpload: uploadOrUpdateMySnap,
        existingSnapId: _myTodaySnapDocId,
      ),
    );
  }
}