// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login.dart'; // 로그아웃 후 이동

// 임시 수면 데이터 구조
class SleepData {
  final String day; // 요일 (Mon, Tue, ...)
  final int score;  // 수면 점수 (0-100)
  final String date; // 날짜 (mm/dd)

  SleepData(this.day, this.score, this.date);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 현재 선택된 하단 네비게이션 인덱스: 0=홈, 1=마이페이지, 2=수면분석
  int _selectedIndex = 0; 
  
  // 주간 수면 패턴 데이터 (더미): 월요일부터 시작하며, 오늘(수요일)까지만 기록 가정
  final List<SleepData> weeklySleepData = [
    SleepData('월', 75, '11/18'),
    SleepData('화', 60, '11/19'),
    SleepData('수', 88, '11/20'), // 오늘 날짜
    SleepData('목', 0, '11/21'),
    SleepData('금', 0, '11/22'),
    SleepData('토', 0, '11/23'),
    SleepData('일', 0, '11/24'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 1. 메뉴창 항목 클릭 핸들러
  void _handleDrawerItemClick(int index) {
    Navigator.pop(context); // Drawer 닫기
    if (index >= 0 && index <= 2) {
      // 마이페이지(1), 수면 분석(2)으로 이동
      setState(() {
        _selectedIndex = index;
      });
    } else {
      // 기타 메뉴 항목 (설정, 노래, 수면 시작)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메뉴 ${index == 3 ? '설정' : index == 4 ? '수면 음악' : '수면 시작'} 기능은 개발 중입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    String displayName = user?.displayName ?? (user?.isAnonymous ?? false ? "게스트" : "사용자");
    
    // Main content widget list (하단 네비게이션에 따라 바뀔 화면)
    final List<Widget> _widgetOptions = <Widget>[
      _buildHomeScreenContent(context, displayName), // 홈
      const Center(child: Text('마이페이지 화면', style: TextStyle(fontSize: 30, color: Color(0xFF1E0C42)))),
      const Center(child: Text('수면 분석 화면', style: TextStyle(fontSize: 30, color: Color(0xFF1E0C42)))),
    ];

    return Scaffold(
      // 1. 상단 중앙 타이틀 및 좌측 메뉴 버튼 (AppBar)
      appBar: AppBar(
        title: const Text('SleepMate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E0C42),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // 메뉴 아이콘 색상
      ),
      
      // 1. 메뉴 창 (Drawer) 구현
      drawer: _buildAppDrawer(context, authService, displayName),

      // 메인 콘텐츠
      body: _widgetOptions.elementAt(_selectedIndex),

      // 5. 하단 Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: '수면 분석',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF7A4EC9), // 선택된 아이템 색상
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  // 홈 화면 콘텐츠 위젯
  Widget _buildHomeScreenContent(BuildContext context, String displayName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 2. 달 이미지 (Placeholder) 및 환영 메시지
          Center(
            child: Column(
              children: [
                // 달 모양 Placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0C42).withOpacity(0.9), // 배경색
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF7A4EC9).withOpacity(0.5), blurRadius: 15),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.brightness_3, size: 70, color: Colors.white), // 큰 달
                        Positioned(
                          top: 25,
                          left: 25,
                          child: Icon(Icons.star, size: 10, color: Colors.yellow[300]),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 15,
                          child: Icon(Icons.star, size: 12, color: Colors.yellow[300]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '$displayName님, 오늘도 깊은 수면을 위해',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const Text(
                  'Sleep Mate와 함께하세요!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 3. 주간 수면 패턴
          _buildSectionTitle('주간 수면 패턴'),
          _buildWeeklySleepChart(),
          
          const SizedBox(height: 30),
          
          // 수면 기록 시작 버튼 (메인 카드)
          _buildMainFeatureCard(context),

          const SizedBox(height: 30),

          // 4. 광고/추천글 섹션
          _buildSectionTitle('질 좋은 수면을 위한 추천'),
          _buildRecommendationCard(
            title: '수면 위생: 더 나은 수면을 위한 5가지 습관',
            summary: '취침 시간 루틴, 카페인 관리, 운동 습관 등 전문가의 조언을 확인하세요.',
            icon: Icons.article_outlined,
            color: const Color(0xFF7A4EC9),
          ),
          _buildRecommendationCard(
            title: '최신 건강 뉴스: 블루라이트와 수면의 관계',
            summary: '잠들기 전 스마트폰 사용이 수면에 미치는 영향에 대한 연구 결과.',
            icon: Icons.campaign_outlined,
            color: Colors.teal,
          ),
          const SizedBox(height: 30),

          // 4. 간단 수면 분석 박스
          _buildSectionTitle('간단 수면 분석 요약'),
          _buildSummaryAnalysisBox(),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- 위젯 빌더 함수 ---

  // 1. Drawer (메뉴 창)
  Widget _buildAppDrawer(BuildContext context, AuthService authService, String displayName) {
    return Drawer(
      child: Column(
        children: <Widget>[
          // 사용자 정보 헤더
          UserAccountsDrawerHeader(
            accountName: Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? '게스트 사용자', style: const TextStyle(fontSize: 14)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(displayName[0], style: const TextStyle(fontSize: 30, color: Color(0xFF1E0C42))),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E0C42),
            ),
          ),
          // 메뉴 항목들
          _buildDrawerItem(icon: Icons.home_outlined, title: '홈', index: 0, onTap: () => _handleDrawerItemClick(0)),
          _buildDrawerItem(icon: Icons.settings_outlined, title: '설정', index: 3, onTap: () => _handleDrawerItemClick(3)),
          _buildDrawerItem(icon: Icons.person_outline, title: '마이페이지', index: 1, onTap: () => _handleDrawerItemClick(1)),
          _buildDrawerItem(icon: Icons.music_note_outlined, title: '수면 음악', index: 4, onTap: () => _handleDrawerItemClick(4)),
          _buildDrawerItem(icon: Icons.play_circle_outline, title: '수면 시작', index: 5, onTap: () => _handleDrawerItemClick(5)),
          _buildDrawerItem(icon: Icons.analytics_outlined, title: '수면 분석', index: 2, onTap: () => _handleDrawerItemClick(2)),
          
          const Spacer(), // 하단에 로그아웃 버튼 위치시키기 위해 사용

          // 로그아웃 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await authService.signOut();
                if (mounted) {
                  // 로그아웃 후 로그인 페이지로 이동 (뒤로 가기 스택 모두 제거)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()), 
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({required IconData icon, required String title, required int index, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? const Color(0xFF7A4EC9) : const Color(0xFF1E0C42)),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? const Color(0xFF7A4EC9) : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E0C42),
        ),
      ),
    );
  }
  
  // 3. 주간 수면 패턴 차트
  Widget _buildWeeklySleepChart() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weeklySleepData.map((data) => _buildDayScoreGauge(data)).toList(),
      ),
    );
  }

  // 3. 개별 요일 수면 점수 게이지 (시계바늘 게이지 느낌)
  Widget _buildDayScoreGauge(SleepData data) {
    Color color;
    if (data.score == 0) {
      color = Colors.grey[300]!;
    } else if (data.score >= 80) {
      color = Colors.green;
    } else if (data.score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    final double gaugeValue = data.score / 100.0;
    final isToday = data.date == '11/20'; 

    return Column(
      children: [
        // 게이지 + 달 아이콘
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: gaugeValue,
                backgroundColor: const Color(0xFFE5E0F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5.0,
              ),
            ),
            Icon(Icons.brightness_3, size: 22, color: data.score > 0 ? color : Colors.grey[500]),
            if (isToday) 
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.star, size: 10, color: const Color(0xFF7A4EC9)), // 오늘 표시
              )
          ],
        ),
        const SizedBox(height: 8),
        // 요일
        Text(data.day, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? const Color(0xFF1E0C42) : Colors.black87, fontSize: 16)),
        // 날짜
        Text(data.date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // 수면 기록 시작 버튼 (메인 카드)
  Widget _buildMainFeatureCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C42),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '지금 바로 수면을 기록하세요',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            '수면 기록을 시작하고 정확한 수면 분석 데이터를 받아보세요.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bedtime_outlined, color: Color(0xFF1E0C42), size: 28),
              label: const Text('수면 기록 시작', style: TextStyle(fontSize: 18, color: Color(0xFF1E0C42), fontWeight: FontWeight.bold)),
              onPressed: () {
                _handleDrawerItemClick(5); // Drawer의 '수면 시작'과 동일한 동작
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A4EC9).withOpacity(0.9), // 밝은 보라색 버튼
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. 추천/광고 카드
  Widget _buildRecommendationCard({required String title, required String summary, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E0C42))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
          ),
          trailing: const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('\'$title\' 자세히 보기 기능은 개발 중입니다.')),
            );
          },
        ),
      ),
    );
  }

  // 4. 간단 수면 분석 요약 박스
  Widget _buildSummaryAnalysisBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E0F0), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어제 수면 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
          ),
          const Divider(height: 25, thickness: 1, color: Color(0xFFE5E0F0)),
          _buildSummaryItem('총 수면 시간', '6시간 45분', Icons.timer_outlined),
          _buildSummaryItem('수면 효율', '88%', Icons.check_circle_outline, Colors.green),
          _buildSummaryItem('깊은 수면', '1시간 20분', Icons.bed_outlined),
          _buildSummaryItem('개선 필요', '취침 불규칙', Icons.warning_amber_outlined, Colors.red),
          
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _onItemTapped(2),
              child: const Text(
                '수면 분석 상세 보기 >',
                style: TextStyle(color: Color(0xFF7A4EC9), fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? const Color(0xFF1E0C42)),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}