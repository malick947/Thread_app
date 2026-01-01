import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Services/authService.dart';
import 'package:the_read_thread/UI/HomeScreen.dart' show Homescreen;
import 'package:the_read_thread/UI/Signup.dart';
import 'package:the_read_thread/UI/forgetPassword.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  Future<void> handleLogin() async {
    setState(() => isLoading = true);

    String? res = await _authService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (res == null) {
      Get.snackbar(
        'success'.tr,
        'login_successful'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.off(() => Homescreen());
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
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/thread_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Welcome
                Text(
                  'welcome_back'.tr,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'continue_your_story'.tr,
                  style: const TextStyle(
                    color: Color(0xFFAE1B25),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'email'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'email_hint'.tr,
                    prefixIcon: const Icon(Icons.email_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFAE1B25),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFAE1B25),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password + Forgot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'password'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    InkWell(
                      onTap: () => Get.to(() => ForgotPasswordScreen()),
                      child: Text(
                        'forgot'.tr,
                        style: const TextStyle(
                          color: Color(0xFFAE1B25),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText:
                        'Enter password', // can be translated too if you want
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFAE1B25),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFAE1B25),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                InkWell(
                  onTap: handleLogin,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAE1B25),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Center(
                            child: Text(
                              'log_in'.tr,
                              style: const TextStyle(
                                color: Colors.white,
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
                    Expanded(child: Divider(color: const Color(0xFFAE1B25))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or_continue_with'.tr,
                        style: const TextStyle(color: Color(0xFFAE1B25)),
                      ),
                    ),
                    Expanded(child: Divider(color: const Color(0xFFAE1B25))),
                  ],
                ),
                const SizedBox(height: 25),

                // Google Button
                InkWell(
                  onTap: () async {
                    final user = await _authService.signInWithGoogle();

                    if (user != null) {
                      Get.snackbar(
                        'success'.tr,
                        '${'logged_in_as'.tr} ${user.email}',
                      );
                      Get.off(() => Homescreen());
                    } else {
                      Get.snackbar('error'.tr, 'google_login_failed'.tr);
                    }
                  },
                  child: _socialButton(
                    icon: FontAwesomeIcons.google,
                    text: 'google'.tr,
                  ),
                ),
                const SizedBox(height: 30),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${'dont_have_account'.tr} '),
                    InkWell(
                      onTap: () => Get.to(() => SignupScreen()),
                      child: Text(
                        'sign_up'.tr,
                        style: const TextStyle(color: Color(0xFFAE1B25)),
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
