import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // [NEW] 브라우저 열기용 패키지
import 'auth_service.dart';
import 'sleep_start_page.dart';
import 'sleep_analysis_page.dart';
import 'package:jangnkangho/screens/mypage.dart'; 
// [NEW] 추천 서비스 임포트
import 'services/recommend_service.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 수면 알람 시간 상태
  TimeOfDay? _sleepAlarmTime;

  // [NEW] 추천 서비스 인스턴스 (Recommendation Service Instance)
  final RecommendationService _recommendationService = RecommendationService();

  // 알람 설정 Time Picker 띄우기
  Future<void> _selectAlarmTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sleepAlarmTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7A4EC9), // 헤더 및 선택 색상
              onSurface: Color(0xFF1E0C42), // 텍스트 색상
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _sleepAlarmTime) {
      setState(() {
        _sleepAlarmTime = picked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수면 알람을 ${_sleepAlarmTime!.format(context)} (으)로 설정했습니다.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Safe Name Initial Getter (안전하게 첫 글자 가져오기)
  String _getInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName![0];
    }
    return (user?.isAnonymous ?? false ? "G" : "U");
  }

  // --- [NEW] 시간 포맷 변환 함수 ---
  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds초'; // 1분 미만은 초 단위 표시
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h시간 $m분';
    return '$m분';
  }

  // --- [NEW] URL 열기 함수 ---
  Future<void> _launchURL(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("기사 링크가 없습니다.")),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication); // 외부 브라우저로 열기
      } else {
        // 일부 기기 호환성을 위해 강제 실행 시도
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("링크를 열 수 없습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // 밝은 배경색
      appBar: AppBar(
        title: const Text('Sleep Mate - 홈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                  (user?.displayName != null && user!.displayName!.isNotEmpty)
                      ? user.displayName!
                      : (user?.isAnonymous ?? false ? "게스트 사용자" : "일반 사용자"),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? "이메일 없음"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(user),
                  style: const TextStyle(fontSize: 40.0, color: Color(0xFF1E0C42)),
                ),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E0C42),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.home, color: Color(0xFF1E0C42)),
              title: Text('홈', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1E0C42)),
              title: const Text('마이페이지', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Color(0xFF1E0C42)),
              title: const Text('수면 분석', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SleepAnalysisPage()),
                );
              },
            ),
            const ListTile(
              leading: Icon(Icons.music_note, color: Color(0xFF1E0C42)),
              title: Text('수면 음악과 테라피', style: TextStyle(fontSize: 16)),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.share, color: Color(0xFF1E0C42)),
              title: Text('나의 수면 패턴 공유', style: TextStyle(fontSize: 16)),
            ),
            const ListTile(
              leading: Icon(Icons.settings, color: Color(0xFF1E0C42)),
              title: Text('설정', style: TextStyle(fontSize: 16)),
            ),
            const ListTile(
              leading: Icon(Icons.support_agent, color: Color(0xFF1E0C42)),
              title: Text('고객 문의', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF1E0C42)),
              title: const Text('로그아웃', style: TextStyle(fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                await authService.signOut();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 중앙 달 모양 섹션 (수정됨: user 파라미터 전달)
              _buildSleepStartSection(context, user),
              const SizedBox(height: 30),

              const Text(
                '주간 수면 패턴',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
              ),
              const SizedBox(height: 15),
              _buildWeeklyPatternSection(),
              const SizedBox(height: 30),

              _buildAlarmSettingSection(context),
              const SizedBox(height: 30),

              _buildAnalysisSummarySection(context),
              const SizedBox(height: 30),

              // [MODIFIED] 실제 기사를 불러오는 추천 섹션
              _buildRecommendationSection(context, user),
            ],
          ),
        ),
      ),
    );
  }

  // --- [MODIFIED] 중앙 달 모양 섹션 위젯 ---
  Widget _buildSleepStartSection(BuildContext context, User? user) {
    return Center(
      child: InkWell(
        onTap: () {
          // 클릭 시 수면 시작 창으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SleepRecordingScreen()),
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B39A3).withOpacity(0.8), // 배경색
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E0C42).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.bedtime_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '오늘의 취침',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E0C42),
              ),
            ),
            // --- [NEW] 최근 수면 시간 표시 ---
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                // Firestore에서 가장 최근 수면 기록 1개를 가져오는 실시간 스트림
                stream: FirebaseFirestore.instance
                    .collection('sleep_records')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('endTime', descending: true) // 중요: 이 부분에서 인덱스 필요 에러가 날 수 있습니다.
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('기록 불러오기 실패', style: TextStyle(fontSize: 12, color: Colors.grey));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text('터치하여 시작하기', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  // 데이터가 있으면 가장 최근 기록 가져오기
                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final int durationSeconds = data['durationSeconds'] ?? 0;
                  final Timestamp? endTime = data['endTime'];
                  
                  // 최근 24시간 이내의 기록인 경우에만 표시 (너무 오래된 기록은 무시)
                  if (endTime != null && DateTime.now().difference(endTime.toDate()).inHours > 24) {
                      return const Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text('터치하여 시작하기', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      "${_formatDuration(durationSeconds)} 잤어요", // 예: 7시간 30분 잤어요
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A4EC9), // 보라색으로 강조
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 주간 수면 패턴 섹션 위젯 (기존 유지)
  Widget _buildWeeklyPatternSection() {
    final List<Map<String, dynamic>> weeklyData = [
      {'day': '월', 'time': '7h 10m', 'status': '양호'},
      {'day': '화', 'time': '6h 30m', 'status': '주의'},
      {'day': '수', 'time': '8h 0m', 'status': '양호'},
      {'day': '목', 'time': '5h 45m', 'status': '주의'},
      {'day': '금', 'time': '7h 50m', 'status': '양호'},
      {'day': '토', 'time': '8h 30m', 'status': '양호'},
      {'day': '일', 'time': '6h 0m', 'status': '주의'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weeklyData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final data = weeklyData[index];
          Color statusColor = data['status'] == '양호' ? Colors.green.shade400 : Colors.orange.shade400;

          return Container(
            width: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['day'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data['time'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 수면 알람 설정 섹션 위젯 (기존 유지)
  Widget _buildAlarmSettingSection(BuildContext context) {
    String alarmTimeDisplay = _sleepAlarmTime == null
        ? '알람을 설정해주세요'
        : _sleepAlarmTime!.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '수면 알람을 설정하세요',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF7A4EC9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alarmTimeDisplay,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _sleepAlarmTime == null ? Colors.grey.shade500 : const Color(0xFF1E0C42),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _selectAlarmTime(context),
                icon: const Icon(Icons.alarm, color: Colors.white),
                label: const Text(
                  '알람 설정',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A4EC9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 간단 수면 분석 요약 섹션 위젯 (기존 유지)
  Widget _buildAnalysisSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '간단 수면 분석 요약',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0C42),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A4EC9).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '지난밤 수면 시간은 7시간 30분으로, 평소보다 15분 더 주무셨습니다. 깊은 수면 단계가 충분하여 수면의 질이 매우 양호합니다.',
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SleepAnalysisPage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    '수면 분석 상세 보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- [MODIFIED] 질 좋은 수면을 위한 추천 섹션 (API 연동) ---
  Widget _buildRecommendationSection(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '질 좋은 수면을 위한 추천',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // 사용자별 추천 기사 로딩 FutureBuilder
          child: user == null
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("로그인 후 확인 가능합니다.")))
              : FutureBuilder<List<Article>>(
                  future: _recommendationService.getPersonalizedArticles(user.uid),
                  builder: (context, snapshot) {
                    // 1. 로딩 중
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Color(0xFF7A4EC9)),
                        ),
                      );
                    }
                    
                    // 2. 에러 발생
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("추천 정보를 불러올 수 없습니다."),
                      );
                    }

                    // 3. 데이터 표시
                    final articles = snapshot.data ?? [];
                    if (articles.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("현재 추천할 기사가 없습니다."),
                      );
                    }

                    return Column(
                      children: articles.map((article) {
                        return ListTile(
                          leading: const Icon(Icons.article, color: Color(0xFF7A4EC9)),
                          title: Text(
                            article.title,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF1E0C42), fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            article.category, // 카테고리 표시 (예: "불면증 극복")
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: const Icon(Icons.open_in_new, size: 20, color: Colors.grey),
                          onTap: () {
                            // [수정됨] 클릭 시 URL 열기
                            _launchURL(context, article.url);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
      ],
    );
  }
}