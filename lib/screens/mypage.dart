import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  // 수면 습관 코드를 한국어로 변환하기 위한 맵
  // UserOnboardingScreen의 _habitOptions와 매칭됩니다.
  final Map<String, String> habitLabelMap = const {
    'LateSleeper': '늦게 잠듦',
    'WakesUp': '수면 중 깸',
    'Snoring': '코골이',
    'Regular': '규칙적 취침',
    'ShortSleep': '짧은 수면 시간',
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인 정보가 없습니다.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // 홈 화면과 통일된 배경색
      appBar: AppBar(
        title: const Text('마이 페이지'),
        backgroundColor: const Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. 에러 발생
          if (snapshot.hasError) {
            return Center(child: Text("오류 발생: ${snapshot.error}"));
          }
          // 3. 데이터 없음
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("저장된 정보가 없습니다."));
          }

          // 4. 데이터 파싱
          // FirestoreService에서 저장한 필드명과 일치해야 합니다.
          final data = snapshot.data!.data() as Map<String, dynamic>;

          final double height = data['height'] ?? 0.0;
          final double weight = data['weight'] ?? 0.0;
          final int age = data['age'] ?? 0;
          final String gender = data['gender'] == 'MALE' ? '남성' : '여성';
          final bool hasCaffeine = data['hasCaffeine'] ?? false;
          final bool hasSmoke = data['hasSmoke'] ?? false;
          final String goal = data['goal'] ?? '목표 없음';
          
          // 습관 리스트 처리
          final List<dynamic> habitsRaw = data['sleepHabits'] ?? [];
          final String habitsStr = habitsRaw.isEmpty 
              ? '선택 안함' 
              : habitsRaw.map((code) => habitLabelMap[code] ?? code).join(', ');

          return SingleChildScrollView(
            child: Column(
              children: [
                // 상단 프로필 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30, top: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E0C42),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.displayName != null && user.displayName!.isNotEmpty
                              ? user.displayName![0]
                              : 'U',
                          style: const TextStyle(fontSize: 40, color: Color(0xFF1E0C42)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        user.displayName ?? '익명 사용자',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        user.email ?? '이메일 없음',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // 상세 정보 카드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildSectionHeader('신체 정보'),
                      _buildInfoCard([
                        _buildRow('성별', gender),
                        _buildDivider(),
                        _buildRow('나이', '$age세'),
                        _buildDivider(),
                        _buildRow('키', '${height.toInt()}cm'),
                        _buildDivider(),
                        _buildRow('몸무게', '${weight.toInt()}kg'),
                      ]),

                      const SizedBox(height: 20),
                      _buildSectionHeader('라이프스타일 & 목표'),
                      _buildInfoCard([
                        _buildRow('카페인 섭취', hasCaffeine ? '함' : '안 함'),
                        _buildDivider(),
                        _buildRow('흡연', hasSmoke ? '함' : '안 함'),
                        _buildDivider(),
                        _buildRow('수면 습관', habitsStr), // 여기에 변환된 습관 문자열 표시
                        _buildDivider(),
                        _buildRow('목표', goal, isLongText: true),
                      ]),
                      
                      const SizedBox(height: 30),
                      
                      // 로그아웃 등의 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('로그아웃', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 섹션 제목
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
      ),
    );
  }

  // 정보 카드 컨테이너
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // 정보 한 줄 (Row)
  Widget _buildRow(String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE));
  }
}