import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'package:the_read_thread/Services/authService.dart';
import 'package:the_read_thread/UI/HomeScreen.dart';
import 'package:the_read_thread/UI/Login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isPasswordVisible = false;
  bool _isLoading = false;

  void handleSignUp() async {
    setState(() => _isLoading = true);

    String? res = await _authService.signUp(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      username: usernameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res == null) {
      Get.snackbar(
        'success'.tr,
        'account_created_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => Homescreen());
    } else {
      Get.snackbar('error'.tr, res, snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // Logo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/thread_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  'join_us'.tr,
                  style: const TextStyle(fontSize: 26, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text(
                  'start_weaving_your_story'.tr,
                  style: const TextStyle(color: Color(0xFFAE1B25), fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Name
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'name'.tr,
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'your_name'.tr,
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFAE1B25)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Username
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'username'.tr,
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: 'username_hint'.tr,
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFAE1B25)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'email'.tr,
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'email_hint'.tr,
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFAE1B25)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'password'.tr,
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'create_password'.tr,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFAE1B25)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFFAE1B25),
                      ),
                      onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAE1B25), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'password_min_length'.tr,
                    style: const TextStyle(color: Color(0xFFAE1B25), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 30),

                // Create Account Button
                InkWell(
                  onTap: _isLoading ? null : handleSignUp,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAE1B25),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'create_account'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Or continue with
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or_continue_with'.tr,
                        style: const TextStyle(color: Color(0xFFAE1B25)),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 15),

                // Google Button
                InkWell(
                  onTap: () async {
                    final user = await _authService.signInWithGoogle();
                    if (user != null) {
                      Get.snackbar(
                        'success'.tr,
                        '${'logged_in_as'.tr} ${user.email}',
                      );
                      Get.offAll(() => Homescreen());
                    } else {
                      Get.snackbar('error'.tr, 'google_login_failed'.tr);
                    }
                  },
                  child: _socialButton(
                    icon: FontAwesomeIcons.google,
                    text: 'google'.tr,
                  ),
                ),

                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${'already_have_account'.tr} '),
                    GestureDetector(
                      onTap: () => Get.off(() => LoginScreen()),
                      child: Text(
                        'log_in'.tr,
                        style: const TextStyle(
                          color: Color(0xFFAE1B25),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFAE1B25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: Colors.black),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}