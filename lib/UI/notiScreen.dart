import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Function to send notification
  Future<void> sendNotification(BuildContext context) async {
    try {
      // Ensure user is authenticated FIRST
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        try {
          UserCredential credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: "tahirmalix947@gmail.com",
                password: "tahirmalix",
              );
          user = credential.user;
        } catch (e) {
          debugPrint("Login failed: $e");
        }
      }

      // Wait a moment to ensure auth state propagates
      await Future.delayed(const Duration(milliseconds: 500));

      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendNotification',
      );

      final result = await callable.call({
        'token':
            'dn3WuREPRTOIkBRnBXtKY9:APA91bFNuPpyszwXyqXbPLWVGCJmSnDoR7VWTERLxcygxUiKm-GSwXXt_xng_USqtRQbkekQraI2SRs5wx7HYYpWIKCJKq4Rv9P9YFUf7JNo0WRyg0zFjnw',
        'title': 'Test',
        'body': 'Hello from Flutter button 🚀',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification sent! ✅')));
      }

      debugPrint("Success: ${result.data}");
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e ❌')));
      }

      debugPrint("Error sending notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Screen"),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => sendNotification(context),
          child: const Text("Send Notification"),
        ),
      ),
    );
  }
}
