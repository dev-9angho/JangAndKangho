import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
// 임시 데이터 관리를 위한 Firestore Import 유지 (실제 데이터 연동 시 사용)
import 'package:cloud_firestore/cloud_firestore.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // AI 팁 상태 관리
  String _aiTip = 'AI 수면 팁을 불러오는 중...';
  
  // 🌟 발전된 디자인을 위한 가상의 핵심 수면 지표 🌟
  double _todayScore = 7.5; // 오늘의 핵심 수면 점수
  final double _goalScore = 8.0; // 목표 수면 시간 (시간)

  final List<Map<String, dynamic>> _detailedMetrics = [
    {'title': '총 수면 시간', 'value': '7시간 30분', 'icon': Icons.access_time_filled, 'color': const Color(0xFF7A4EC9)},
    {'title': '깊은 수면', 'value': '1시간 45분', 'icon': Icons.bedtime_rounded, 'color': const Color(0xFF1E0C42)},
    {'title': 'REM 수면', 'value': '2시간 15분', 'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFF5B39A3)},
  ];

  // 주간 점수 데이터 (기존 복원 데이터 유지)
  final List<Map<String, dynamic>> _weeklySleepData = [
    {'day': '일', 'score': 6.5, 'color': const Color(0xFF7A4EC9)},
    {'day': '월', 'score': 7.0, 'color': const Color(0xFF7A4EC9)},
    {'day': '화', 'score': 5.8, 'color': const Color(0xFF5B39A3)},
    {'day': '수', 'score': 7.5, 'color': const Color(0xFF1E0C42)},
    {'day': '목', 'score': 6.2, 'color': const Color(0xFF7A4EC9)},
    {'day': '금', 'score': 8.0, 'color': const Color(0xFF1E0C42)},
    {'day': '토', 'score': 7.3, 'color': const Color(0xFF7A4EC9)},
  ];

  // Firebase Functions 호출 함수 (AI 수면 팁 가져오기)
  Future<void> _fetchAiSleepTip() async {
    setState(() {
      _aiTip = '사용자 데이터를 분석하여 팁을 생성하고 있어요...';
    });
    
    // 현재 점수를 포함하여 AI 함수 호출
    final userData = {
      'latestScore': _todayScore, 
      'averageScore': _weeklySleepData.map((e) => e['score'] as double).reduce((a, b) => a + b) / _weeklySleepData.length,
      'sleepGoal': _goalScore, 
    };

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getSleepTip');

      final result = await callable.call(userData);
      
      final tip = result.data['tip'] as String? ?? '팁을 가져오는 데 실패했습니다.';

      if (mounted) {
        setState(() {
          _aiTip = tip;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Firebase Functions Error: ${e.code} - ${e.message}');
      }
      if (mounted) {
        setState(() {
          _aiTip = '팁 로딩 실패 (코드: ${e.code}). Firebase Functions 로그를 확인해 주세요.';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('General Error: $e');
      }
      if (mounted) {
        setState(() {
          _aiTip = '알 수 없는 오류가 발생했습니다.';
        });
      }
    }
  }

  // URL 런치 함수
  void _launchSleepInfoUrl() async {
    const urlString = 'https://www.sleepfoundation.org/sleep-hygiene';
    final uri = Uri.parse(urlString);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('웹사이트를 열 수 없습니다: $urlString')),
        );
      }
    }
  }
  
  // State 초기화 시 AI 팁 로딩 시작
  @override
  void initState() {
    super.initState();
    _fetchAiSleepTip(); 
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<User?>(context);

    return Scaffold(
      drawer: _buildDrawer(context, authService, user),
      
      appBar: AppBar(
        title: const Text('Sleep Mate'),
        backgroundColor: const Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 알림 아이콘
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능은 준비 중입니다.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 🌟 1. 메인 점수 및 원형 차트 섹션 🌟
            _buildMainScoreCard(),
            
            const SizedBox(height: 25),

            // 🌟 2. 상세 수면 지표 섹션 🌟
            _buildDetailedMetrics(),

            const SizedBox(height: 30),

            // 주간 요약
            const Text(
              '주간 수면 성과',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
            ),
            const SizedBox(height: 15),

            // 주간 요일별 수면 점수 그래프
            _buildWeeklyScoreChart(),
            
            const SizedBox(height: 30),

            // 🌟 3. AI 수면 팁 섹션 🌟
            _buildAiTipCard(),

            const SizedBox(height: 20),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: _fetchAiSleepTip,
                icon: const Icon(Icons.refresh),
                label: const Text('새로운 AI 팁 받기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A4EC9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 원형 차트가 포함된 메인 점수 카드 위젯 🌟
  Widget _buildMainScoreCard() {
    // 10점 만점 기준 진행률
    double progress = _todayScore / 10.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0C42), // 진한 보라색 배경
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '오늘의 수면 점수',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 원형 진행률 표시기
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7A4EC9)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_todayScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/ 10점 만점',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _todayScore >= 7.0 ? '👍 목표 달성! 좋은 수면이었습니다.' : '🤔 조금 더 숙면이 필요해 보여요.',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  // 🌟 상세 수면 지표 위젯 🌟
  Widget _buildDetailedMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상세 수면 지표',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // ScrollView 중첩 방지
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8, // 카드의 세로 비율 조정
          ),
          itemCount: _detailedMetrics.length,
          itemBuilder: (context, index) {
            final metric = _detailedMetrics[index];
            return _buildMetricTile(metric['title'] as String, metric['value'] as String, metric['icon'] as IconData, metric['color'] as Color);
          },
        ),
      ],
    );
  }
  
  // 개별 수면 지표 타일 위젯
  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }


  // 주간 점수 차트 위젯 (복원된 디자인 유지)
  Widget _buildWeeklyScoreChart() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _weeklySleepData.map((data) => _buildScoreBar(data)).toList(),
      ),
    );
  }

  // 개별 점수 바 위젯
  Widget _buildScoreBar(Map<String, dynamic> data) {
    // 점수를 10점 만점으로 가정하고 높이 비율 계산
    double score = data['score'] as double;
    Color color = data['color'] as Color;
    double normalizedHeight = score / 10.0; 

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 5),
        Container(
          height: 100 * normalizedHeight, // 최대 높이 100으로 설정
          width: 25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data['day'] as String,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  // AI 팁 카드 위젯 
  Widget _buildAiTipCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFFF7F4FF), // 연한 보라색 배경
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF7A4EC9), size: 24),
                SizedBox(width: 8),
                Text(
                  '오늘의 AI 수면 팁',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF7A4EC9)
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Color(0xFFE0D9F7)),
            Text(
              _aiTip,
              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _launchSleepInfoUrl,
                icon: const Icon(Icons.link, size: 16),
                label: const Text('수면 건강 정보 (Sleep Foundation)', style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5B39A3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 드로어 위젯 (복원 및 사용자 정보 표시)
  Widget _buildDrawer(BuildContext context, AuthService authService, User? user) {
    final displayEmail = user?.email ?? "게스트 모드";
    final displayName = user?.displayName ?? "사용자님";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(displayEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1E0C42)),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E0C42),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF7A4EC9)),
            title: const Text('홈'),
            onTap: () {
              Navigator.pop(context); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment, color: Color(0xFF7A4EC9)),
            title: const Text('수면 분석 리포트'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수면 분석 리포트 페이지로 이동합니다.')),
              );
              Navigator.pop(context); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF7A4EC9)),
            title: const Text('설정'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정 페이지로 이동합니다.')),
              );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃'),
            onTap: () async {
              Navigator.pop(context); 
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}