import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧠 Sign up with email and password
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // 🔥 Set Display Name in Firebase Auth
        await user.updateDisplayName(name);
        await user.reload(); // Refresh user data

        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
          'memories_knotted': 0,
          'total_threads': 0,
        });
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// 🔐 Login with email and password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  /// 🚪 Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 👤 Get current user
  User? get currentUser => _auth.currentUser;

  /// 🔄 Stream of auth state changes (useful for checking if logged in/out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------------------------------
  // GOOGLE SIGN-IN  (google_sign_in: 6.2.1)
  // -------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      /// Step 1 — Choose Account
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // cancelled

      /// Step 2 — Get ID Token & Access Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      /// Step 3 — Create Firebase Credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      /// Step 4 — Firebase Login
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        // Check if user already exists
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          // Create new user entry
          await userDoc.set({
            'uid': user.uid,
            'name': user.displayName ?? googleUser.displayName ?? '',
            'email': user.email ?? googleUser.email,
            'createdAt': FieldValue.serverTimestamp(),
            'memories_knotted': 0,
            'total_threads': 0,
            'username': "@GmailUser",
          });
        }
      }

      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent to your email")),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";

      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _waitForProfileCreation(String uid) async {
  // Wait for the user document to appear in Firestore
  for (int i = 0; i < 10; i++) { // Try 10 times with 500ms intervals
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    if (doc.exists) {
      print('✅ Profile found in Firestore after ${i + 1} attempts');
      return true;
    }
    
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('❌ Profile not found in Firestore after 5 seconds');
  return false;
}
}
