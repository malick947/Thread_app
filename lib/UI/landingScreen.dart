import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Already have this
import 'package:the_read_thread/UI/Login.dart';
import 'package:the_read_thread/utiles/buttons.dart';

class Landingscreen extends StatelessWidget {
  const Landingscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/thread_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'app_title'.tr, // ← Magic: auto-updates on language change
              style: const TextStyle(fontSize: 30, color: Color(0xFFAE1B25)),
            ),
            Text(
              'app_subtitle'.tr,
              style: const TextStyle(fontSize: 15, color: Color(0x66AE1B25)),
            ),

            // Temporary test buttons
            const SizedBox(height: 40),
            
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 100,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
          child: RedButtonContainer(
            text: 'start_weaving'.tr,
            postIcon: Icons.arrow_forward,
            isBold: true,
            onTap: () {
              Get.to(() => const LoginScreen());
            },
          ),
        ),
      ),
    );
  }
}