import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Services/authService.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'enter_email_reset_link'.tr,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('please_enter_your_email'.tr),
                      ),
                    );
                    return;
                  }

                  authService.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                    context: context,
                  );
                },
                child: Text('send_reset_link'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}