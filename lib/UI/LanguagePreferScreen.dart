import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_read_thread/UI/Login.dart';
import 'package:the_read_thread/UI/landingScreen.dart';
import 'package:the_read_thread/utiles/buttons.dart'; // Assuming this contains RedButtonContainer

class LanguagePreferenceScreen extends StatelessWidget {
  const LanguagePreferenceScreen({super.key});

  // Function to change & SAVE language
  Future<void> _setMyPreferredLanguage(String langCode, String countryCode) async {
    // 1. Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode);
    await prefs.setString('countryCode', countryCode);

    // 2. Apply new locale immediately
    Get.updateLocale(Locale(langCode, countryCode));

    // 3. Optional: Show nice message
    Get.snackbar(
      'language_changed'.tr,
      'app_now_in_language'.trParams({'lang': langCode.toUpperCase()}),
      backgroundColor: Color(0xFFAE1B25),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // 4. Navigate to next screen (Splash → AuthCheck)
    Get.off(() => const Landingscreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/thread_logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'choose_your_language'.tr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAE1B25),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'select_language_to_continue'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Language Buttons
                RedButtonContainer(
                  text: 'English',
                  postIcon: Icons.language,
                  isBold: true,
                  onTap: () => _setMyPreferredLanguage('en', 'US'),
                ),
                const SizedBox(height: 20),

                RedButtonContainer(
                  text: 'Français',
                  postIcon: Icons.language,
                  isBold: true,
                  onTap: () => _setMyPreferredLanguage('fr', 'FR'),
                ),
                const SizedBox(height: 20),

                RedButtonContainer(
                  text: 'Italiano',
                  postIcon: Icons.language,
                  isBold: true,
                  onTap: () => _setMyPreferredLanguage('it', 'IT'),
                ),
                const SizedBox(height: 20),

                RedButtonContainer(
                  text: 'Español',
                  postIcon: Icons.language,
                  isBold: true,
                  onTap: () => _setMyPreferredLanguage('es', 'ES'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}