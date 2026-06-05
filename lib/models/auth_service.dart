// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? lastError;
  bool _isInitialized = false;

  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Ensures GoogleSignIn is initialized. Required in v7.0.0+
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        serverClientId:
            '962901246025-1g6qvc81cv1aaubeelk5paj877dnj3pl.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  /// Generates a fresh credential for re-authenticating before sensitive actions
  Future<AuthCredential?> getGoogleReauthCredential() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    } catch (e) {
      if (e.toString().contains('canceled') ||
          e.toString().contains('sign_in_canceled')) {
        return null;
      }
      debugPrint("Google Re-auth failed: $e");
      return null;
    }
  }

  /// Handles Google Sign-In with callbacks for incomplete profile and success
  Future<void> signInWithGoogle({
    required void Function(String? email, String? photoUrl) onIncompleteProfile,
    required VoidCallback onSuccess,
  }) async {
    try {
      await _ensureInitialized();

      if (_firebaseAuth.currentUser != null) {
        await signOut();
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        final String? email = user.email;
        final String? photoUrl = user.photoURL;

        DocumentReference userDoc = _firestore
            .collection('Users')
            .doc(user.uid);
        DocumentSnapshot docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          onIncompleteProfile(email, photoUrl);
          return;
        }

        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;

        if (data == null || data['name'] == null || data['phone'] == null) {
          onIncompleteProfile(email, photoUrl);
          return;
        }

        onSuccess();
      }
    } catch (e) {
      if (e.toString().contains('canceled') ||
          e.toString().contains('sign_in_canceled')) {
        lastError = "Google Sign-In was cancelled.";
        debugPrint(lastError);
        return;
      }
      lastError = "Google Sign-In failed: $e";
      debugPrint(lastError);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
