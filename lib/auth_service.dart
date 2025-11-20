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
      // 웹 환경에서는 팝업/리다이렉트를 유도합니다. (FlutterFire가 플랫폼별로 처리)
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

  // --- 3. Sign Out Method (오류 발생 가능성 최소화) ---
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      
      // 참고: _firebaseAuth.signOut()이 성공하면, authStateChanges() 스트림에
      // null 값이 전달되어 Provider를 사용하는 AuthWrapper가 자동으로 로그인 페이지로 이동시킵니다.
      
    } on Exception catch (e) { // FirebaseAuthException 대신 Exception을 사용하여 더 넓은 범위의 런타임 오류 포착
      if (kDebugMode) {
        // 디버그 모드에서만 오류 로그를 출력합니다.
        debugPrint('Sign Out Error: $e');
      }
      // 오류가 발생하더라도 앱의 UI/흐름이 멈추지 않도록 예외를 다시 던지지 않습니다.
    }
  }

  // 4. Get Current User
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}