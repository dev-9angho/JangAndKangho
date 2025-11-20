// lib/auth_service.dart (GoogleSignIn 제거 최종본)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart'; 

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get user => _firebaseAuth.authStateChanges(); 

  // --- 1. Google Sign-In Method (Firebase Auth Only) ---
  Future<User?> signInWithGoogle() async { 
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      // GoogleSignIn 패키지 없이 Firebase Auth의 기본 기능을 사용
      final UserCredential userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      return userCredential.user; 
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Google 로그인 오류 (Firebase Auth): ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('General Sign-In Error: $e');
      }
      return null;
    }
  }

  // --- 2. 익명 로그인 메서드 ---
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInAnonymously();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Anonymous Sign-In Error: ${e.code} - ${e.message}');
      }
      return null;
    }
  }

  // --- 3. Sign Out Method ---
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sign Out Error: $e');
      }
    }
  }

  // 4. Get Current User
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}