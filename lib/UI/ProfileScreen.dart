import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for language persistence
import 'package:the_read_thread/Controller/ProfileController.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/UserProfileModel.dart';
import 'package:the_read_thread/UI/AccountSettings.dart';
import 'package:the_read_thread/UI/NotificationSettings.dart';
import 'package:the_read_thread/UI/PrivacySettings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // NEW: Function to change and save language preference
  Future<void> _changeLanguage(String langCode, String countryCode) async {
    final locale = Locale(langCode, countryCode);

    // Apply immediately
    Get.updateLocale(locale);

    // Save to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
    await prefs.setString('countryCode', countryCode);

    // Show nice confirmation
    Get.snackbar(
      'language_changed'.tr,
      'app_now_in_language'.trParams({'lang': langCode.toUpperCase()}),
      backgroundColor: Color(0xFFAE1B25),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());
    final FriendsController friendsController = Get.find<FriendsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.profile.value;
        if (user == null) {
          return Center(
            child: Text(
              'profile_not_found'.tr,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final initials = user.name.isNotEmpty
            ? user.name
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .map((e) => e[0].toUpperCase())
                  .take(2)
                  .join()
            : "ME";

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 5),
              Text("profile".tr, style: TextStyle(fontSize: 25)),
              const SizedBox(height: 10),
              // Profile Picture + Camera Icon
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFAE1B25), width: 5),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      backgroundColor: const Color(0xFF293035),
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _changeMyDP(controller),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFAE1B25),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name + Edit Icon
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFFAE1B25),
                      size: 20,
                    ),
                    onPressed: () =>
                        _showEditProfileDialog(context, controller, user),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                user.about.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              // Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      user.totalThreads.toString(),
                      'total_threads'.tr,
                    ),
                    _buildStat(
                      user.memoriesKnotted.toString(),
                      'memories_knotted'.tr,
                    ),
                    _buildStat(
                      friendsController.friends.length.toString(),
                      'friends'.tr,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Settings Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text('settings'.tr, style: TextStyle(fontSize: 20)),
              ),

              const SizedBox(height: 16),

              // Settings List with Navigation
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'notifications'.tr,
                onTap: () => Get.to(
                  () => const NotificationsSettings(),
                  transition: Transition.leftToRight,
                  duration: Duration(microseconds: 400),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'privacy'.tr,
                onTap: () => Get.to(
                  () => PrivacySettings(),
                  transition: Transition.leftToRight,
                  duration: Duration(microseconds: 400),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.location_on_outlined,
                title: 'location_access'.tr,
                onTap: () async {
                  final status = await Permission.location.request();
                  if (status.isGranted || status.isLimited) {
                    openAppSettings();
                    Get.snackbar(
                      'granted'.tr,
                      'location_access_enabled'.tr,
                      backgroundColor: Color(0xFFAE1B25),
                      colorText: Colors.white,
                    );
                  } else if (status.isDenied) {
                    Get.snackbar(
                      'denied'.tr,
                      'location_permission_needed'.tr,
                      backgroundColor: Color(0xFFAE1B25),
                      colorText: Colors.white,
                    );
                  } else if (status.isPermanentlyDenied) {
                    openAppSettings();
                    Get.snackbar(
                      'open_settings'.tr,
                      'enable_location_in_system_settings'.tr,
                      backgroundColor: Color(0xFFAE1B25),
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'account'.tr,
                onTap: () => Get.to(
                  () => const AccountSettings(),
                  transition: Transition.leftToRight,
                  duration: Duration(microseconds: 400),
                ),
              ),

              // NEW: Language Selection Dropdown
              Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.language, color: Colors.grey[700]),
                  title: Text('language'.tr),
                  trailing: DropdownButton<String>(
                    value: Get.locale?.languageCode ?? 'en',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'it', child: Text('Italiano')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                    ],
                    onChanged: (String? newLang) {
                      if (newLang != null) {
                        String country = newLang == 'en'
                            ? 'US'
                            : newLang.toUpperCase();
                        _changeLanguage(newLang, country);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.logout(),
                  icon: const Icon(Icons.logout, color: Color(0xFFAE1B25)),
                  label: Text(
                    'logout'.tr,
                    style: TextStyle(fontSize: 18, color: Color(0xFFAE1B25)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Color(0xFFAE1B25), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  // Helper: Stat Column
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 36, color: Color(0xFFAE1B25)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
        ),
      ],
    );
  }

  // Settings Tile with Custom onTap
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Change Profile Picture
  void _changeMyDP(ProfileController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'profile_picture'.tr,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFAE1B25)),
              title: Text('take_photo'.tr),
              onTap: () => _pickImage(controller, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFAE1B25),
              ),
              title: Text('choose_from_gallery'.tr),
              onTap: () => _pickImage(controller, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Pick & Upload Image
  Future<void> _pickImage(
    ProfileController controller,
    ImageSource source,
  ) async {
    Get.back();
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image == null) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not logged in";

      final ref = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/profile.jpg',
      );
      await ref.putFile(File(image.path));
      final photoUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoUrl': photoUrl},
      );
      await controller.fetchCurrentUserProfile();

      Get.back();
      Get.snackbar(
        'success'.tr,
        'profile_picture_updated'.tr,
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'error'.tr,
        '${'failed'.tr}: $e',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    }
  }

  // Edit Name & About
  void _showEditProfileDialog(
    BuildContext context,
    ProfileController controller,
    UserProfileModel user,
  ) {
    final usernameController = TextEditingController(text: user.username);
    final aboutController = TextEditingController(text: user.about);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'edit_profile'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  'username'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'status'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                TextField(
                  controller: aboutController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E9EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'cancel'.tr,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            Get.dialog(
                              const Center(child: CircularProgressIndicator()),
                              barrierDismissible: false,
                            );

                            final uid =
                                FirebaseAuth.instance.currentUser?.uid ?? "";
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                                  "username": usernameController.text.trim(),
                                  "about": aboutController.text.trim(),
                                });

                            await controller.fetchCurrentUserProfile();

                            Get.back();
                            Get.back();

                            Get.snackbar(
                              'success'.tr,
                              'profile_updated'.tr,
                              backgroundColor: Color(0xFFAE1B25),
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.back();
                            Get.snackbar(
                              'error'.tr,
                              'update_failed'.tr,
                              backgroundColor: Color(0xFFAE1B25),
                              colorText: Colors.white,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAE1B25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'save'.tr,
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
