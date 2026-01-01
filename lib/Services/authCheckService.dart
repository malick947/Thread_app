// auth_check.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_read_thread/UI/HomeScreen.dart';
import 'package:the_read_thread/UI/LanguagePreferScreen.dart';
import 'package:the_read_thread/UI/Login.dart';
import 'package:the_read_thread/UI/landingScreen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state (first load)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFAE1B25)),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const Homescreen(); // Replace with your main app screen
        }

        // User is NOT logged in
        //return const Landingscreen(); // Replace with your login/signup flow
        return LanguagePreferenceScreen();
      },
    );
  }
}
