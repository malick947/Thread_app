// controllers/ProfileController.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Model/UserProfileModel.dart';
import 'package:the_read_thread/UI/Login.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var profile = Rxn<UserProfileModel>();
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUserProfile();
  }

  Future<void> fetchCurrentUserProfile() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar("Error", "No user logged in",backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,);
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        print('I have founded my profile');
        profile.value = UserProfileModel.fromMap(doc.data()!, doc.id);
      } else {
        Get.snackbar("Error", "Profile not found",backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load profile",backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.off(LoginScreen()); // or your login route
  }
}
