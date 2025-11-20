import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // ⭐️ 경로 수정

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider.of<User?> 사용을 위해 User 임포트가 필수
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    // 사용자 정보 표시
    String displayEmail = user?.email ?? "없음";
    String displayUid = user?.uid ?? "알 수 없음";
    String displayName = user?.displayName ?? (user?.isAnonymous ?? false ? "게스트 사용자" : "일반 사용자");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Mate - 홈'),
        backgroundColor: const Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '로그인 성공!',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
              ),
              const SizedBox(height: 20),
              // ... (나머지 UI 코드)
              _buildUserInfoTile('로그인 방식', user?.isAnonymous ?? true ? '게스트 (익명)' : '이메일', Icons.person),
              _buildUserInfoTile('표시 이름', displayName, Icons.badge),
              _buildUserInfoTile('이메일', displayEmail, Icons.email),
              _buildUserInfoTile('UID', displayUid, Icons.vpn_key),
              
              const SizedBox(height: 40),
              const Text(
                '이곳에 앱의 주요 콘텐츠 (수면 분석, 마이페이지 등)가 표시됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(String title, String value, IconData icon) {
    // ... (기존 _buildUserInfoTile 함수 유지)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7A4EC9), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E0C42)),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}