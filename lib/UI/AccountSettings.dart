import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/UI/Login.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  Future<void> _changePassword() async {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'change_password_title'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: currentPassword,
                  hint: 'enter_current_password'.tr,
                  validator: (val) => val!.isEmpty ? 'required'.tr : null,
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: newPassword,
                  hint: 'enter_new_password'.tr,
                  validator: (val) {
                    if (val!.isEmpty) return 'required'.tr;
                    if (val.length < 6) return 'minimum_6_characters'.tr;
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: confirmPassword,
                  hint: 'confirm_new_password'.tr,
                  validator: (val) {
                    if (val != newPassword.text)
                      return 'passwords_do_not_match'.tr;
                    return null;
                  },
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;

                      Get.back();
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) throw "Not logged in";

                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPassword.text,
                        );

                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPassword.text);

                        Get.back();
                        Get.back();

                        Get.snackbar(
                          'success'.tr,
                          'password_changed_successfully'.tr,
                          backgroundColor: Color(0xFFAE1B25),
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.back();
                        String msg = 'failed_to_change_password'.tr;
                        if (e.toString().contains("wrong-password")) {
                          msg = 'current_password_incorrect'.tr;
                        }
                        Get.snackbar(
                          'error'.tr,
                          msg,
                          backgroundColor: Color(0xFFAE1B25),
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAE1B25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'update_password'.tr,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: true,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFAE1B25),
                size: 60,
              ),

              const SizedBox(height: 16),

              Text(
                'delete_account_title'.tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                'permanent_action_data_lost'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 22),

              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'type_delete_to_confirm'.tr,
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 28),

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
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (confirmController.text.trim() != "DELETE") {
                          Get.snackbar(
                            'error'.tr,
                            'type_delete_to_confirm'.tr,
                            backgroundColor: Color(0xFFAE1B25),
                            colorText: Colors.white,
                          );
                          return;
                        }

                        Get.back();
                        Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                          barrierDismissible: false,
                        );

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw "Not logged in";

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .delete();

                          try {
                            await FirebaseStorage.instance
                                .ref('users/${user.uid}/profile.jpg')
                                .delete();
                          } catch (_) {}

                          await user.delete();

                          Get.off(LoginScreen());

                          Get.snackbar(
                            'deleted'.tr,
                            'account_deleted'.tr,
                            backgroundColor: Color(0xFFAE1B25),
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'error'.tr,
                            'failed_to_delete_account'.tr,
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
                          'delete_forever'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('account'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'manage_your_account_settings'.tr,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            'account_information'.tr,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          Card(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.grey),
              title: Text('email'.tr),
              subtitle: Text(user?.email ?? 'not_available'.tr),
            ),
          ),

          const SizedBox(height: 24),
          Text('security'.tr, style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.grey),
                  title: Text('change_password'.tr),
                  subtitle: Text('update_your_password'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
                Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: Colors.grey,
                  ),
                  title: Text('two_factor_authentication'.tr),
                  subtitle: Text('add_extra_layer_security'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Get.snackbar('coming_soon'.tr, 'two_fa_coming_soon'.tr,
                          backgroundColor: Color(0xFFAE1B25),
                          colorText: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'danger_zone'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFAE1B25),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Color(0xFFAE1B25),
              ),
              title: Text(
                'delete_account'.tr,
                style: TextStyle(color: Color(0xFFAE1B25)),
              ),
              subtitle: Text('permanently_delete_account_data'.tr),
              onTap: _deleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}