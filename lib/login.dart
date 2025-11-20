// lib/login.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'auth_service.dart'; // 경로는 필요에 따라 수정하세요 (예: 'auth_service.dart')

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Google 로그인 버튼 액션
  void _handleGoogleSignIn(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? user = await authService.signInWithGoogle();

    if (!context.mounted) return; // context.mounted 체크 추가

    if (user != null) {
      _showSnackbar(context, "Google 로그인 성공!");
    } else {
      _showSnackbar(context, "Google 로그인 실패 또는 취소됨.");
    }
  }

  // 게스트 로그인 버튼 액션
  void _handleGuestSignIn(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? user = await authService.signInAnonymously();

    if (!context.mounted) return; // context.mounted 체크 추가

    if (user != null) {
      _showSnackbar(context, "게스트로 로그인 성공! (UserID: ${user.uid})");
    } else {
      _showSnackbar(context, "게스트 로그인 실패.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 배경
          Container(
            color: const Color(0xFF1E0C42), // 어두운 보라색 계열 배경색
            // Image.asset(...)을 사용하여 배경 이미지를 지정할 수 있습니다.
          ),
          
          // 2. 중앙 콘텐츠
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // 'login' 텍스트
                  const Text(
                    'login',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(height: 10), 

                          // Google 로그인 버튼 
                          ElevatedButton(
                            onPressed: () => _handleGoogleSignIn(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.grey, width: 0.5),
                              ),
                              elevation: 1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google 로고 (에셋이 없을 경우 대비)
                                Image.asset(
                                  'assets/google_logo.png', 
                                  height: 24.0,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 30),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Google로 로그인',
                                  style: TextStyle(fontSize: 18, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 게스트 로그인 버튼
                          ElevatedButton(
                            onPressed: () => _handleGuestSignIn(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: const Color(0xFF7A4EC9), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            child: const Text(
                              '게스트로 시작하기',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}