import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'screens/user_onboarding_screen.dart'; // 다음 단계: 온보딩 화면

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // 로그인 성공/실패 시 사용자에게 피드백을 주기 위한 함수
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 로그인 후 온보딩 화면으로 이동하는 로직
  void _navigateToNextScreen(BuildContext context) {
    // 로그인 페이지 스택을 제거하고 온보딩 페이지로 이동합니다.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UserOnboardingScreen()),
    );
  }

  // Google 로그인 버튼 액션
  void _handleGoogleSignIn(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userCredential = await authService.signInWithGoogle();

    if (userCredential != null) {
      _showSnackbar(context, "Google 로그인 성공!");
      _navigateToNextScreen(context);
    } else {
      _showSnackbar(context, "Google 로그인 실패 또는 취소됨.");
    }
  }

  // 게스트 로그인 버튼 액션
  void _handleGuestSignIn(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.signInAnonymously();

    if (user != null) {
      _showSnackbar(context, "게스트로 로그인 성공! (UserID: ${user.uid.substring(0, 8)}...)");
      _navigateToNextScreen(context);
    } else {
      _showSnackbar(context, "게스트 로그인 실패.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // 배경에 보라색 그라데이션 적용
          gradient: LinearGradient(
            colors: [Color(0xFF1E0C42), Color(0xFF7A4EC9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 앱 로고/타이틀
                const Text(
                  'SleepMate',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '당신의 숙면을 위한 동반자',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 80),

                // 로그인 카드 영역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    padding: const EdgeInsets.all(30.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          '시작하기',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
                        ),
                        const SizedBox(height: 30),

                        // Google 로그인 버튼
                        ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/google_logo.png', // ⚠️ 로컬 에셋이 없으므로 임시로 Icon 대체
                            height: 24.0,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.black, size: 30),
                          ),
                          label: const Text(
                            'Google로 계속하기',
                            style: TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                          onPressed: () => _handleGoogleSignIn(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.white, // 흰색 버튼
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            elevation: 1,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 구분선
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text('또는', style: TextStyle(color: Colors.grey[600])),
                            ),
                            const Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // 게스트 로그인 버튼
                        ElevatedButton(
                          onPressed: () => _handleGuestSignIn(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF7A4EC9), // 보라색 계열 버튼
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            '게스트로 시작하기',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 이메일/비밀번호 로그인 부분은 다음 단계에서 추가 가능
                        TextButton(
                          onPressed: () {
                            _showSnackbar(context, '이메일/비밀번호 로그인 기능은 준비 중입니다.');
                          },
                          child: const Text(
                            '이메일로 로그인/가입',
                            style: TextStyle(color: Color(0xFF1E0C42)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}