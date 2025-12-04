import 'package:flutter/material.dart';
import 'package:jangnkangho/music.dart';
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
                  MaterialPageRoute(builder: (context) =>  MyPage()),
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
                  MaterialPageRoute(builder: (context) => SleepAnalysisPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.music_note, color: Color(0xFF1E0C42)),
              title: Text('수면 음악과 테라피', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context); // Drawer 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SleepMusicPage()), // [NEW] 이동
                );
              },
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
              _buildWeeklyPatternSection(user),
              const SizedBox(height: 30),

              _buildAlarmSettingSection(context),
              const SizedBox(height: 30),

              _buildAnalysisSummarySection(context,user),
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
                stream: FirebaseFirestore.instance
                    .collection('sleep_records')
                    .where('userId', isEqualTo: user.uid)
                    // "오늘 00시 00분 이후에 끝난" 모든 기록을 가져옵니다.
                    .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('기록 불러오기 실패', style: TextStyle(fontSize: 12, color: Colors.grey));
                  
                  // 데이터가 없거나 비어있으면
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text('터치하여 시작하기', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  // [핵심 로직] 가져온 모든 기록의 시간(durationSeconds)을 더합니다.
                  int totalSecondsToday = 0;
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    totalSecondsToday += (data['durationSeconds'] as int? ?? 0);
                  }

                  // 합산된 시간이 0이면 시작하기 문구 표시
                  if (totalSecondsToday == 0) {
                     return const Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text('터치하여 시작하기', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      "${_formatDuration(totalSecondsToday)} 잤어요", // 총합 시간 표시
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A4EC9),
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

    // --- [MODIFIED] 주간 수면 패턴 섹션 (Firestore 연동) ---
// --- [UPDATED] 주간 수면 패턴 섹션 (점수 표시 추가됨) ---
  Widget _buildWeeklyPatternSection(User? user) {
    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime startOfWeek = DateTime(monday.year, monday.month, monday.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sleep_records')
          .where('userId', isEqualTo: user.uid)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .orderBy('startTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("데이터 로딩 실패");
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
        }

        // 1. 데이터 집계용 변수 초기화
        Map<int, int> weeklyDuration = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        Map<int, int> weeklyScoreSum = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}; // [NEW] 점수 합계
        Map<int, int> weeklyCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};    // [NEW] 기록 횟수 (평균 계산용)

        // 2. 데이터 집계
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Timestamp? start = data['startTime'];
            int duration = data['durationSeconds'] ?? 0;
            int score = data['sleepScore'] ?? 0; // [NEW] 점수 가져오기

            if (start != null) {
              int weekday = start.toDate().weekday;
              
              weeklyDuration[weekday] = (weeklyDuration[weekday] ?? 0) + duration;
              weeklyScoreSum[weekday] = (weeklyScoreSum[weekday] ?? 0) + score; // 점수 누적
              weeklyCount[weekday] = (weeklyCount[weekday] ?? 0) + 1;           // 횟수 증가
            }
          }
        }

        List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];
        
        return SizedBox(
          height: 110, // [TIP] 점수 텍스트가 들어가야 해서 높이를 조금 늘렸습니다.
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              int weekdayKey = index + 1;
              int totalSeconds = weeklyDuration[weekdayKey] ?? 0;
              
              // [NEW] 평균 점수 계산
              int totalScore = weeklyScoreSum[weekdayKey] ?? 0;
              int count = weeklyCount[weekdayKey] ?? 0;
              int avgScore = count > 0 ? (totalScore ~/ count) : 0; // 0으로 나누기 방지

              String timeStr = _formatSimpleDuration(totalSeconds);
              
              // 상태 판단 (점수가 있으면 점수 기준, 없으면 시간 기준)
              Color statusColor;
              if (totalSeconds == 0) {
                statusColor = Colors.grey.shade300;
              } else if (avgScore >= 80) { // 80점 이상이면 초록
                statusColor = Colors.green.shade400;
              } else if (avgScore >= 50) { // 50점 이상이면 주황
                statusColor = Colors.orange.shade400;
              } else { // 그 외 빨강
                statusColor = Colors.redAccent.shade200;
              }

              return Container(
                width: 70, // 카드 너비
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
                    // 요일
                    Text(
                      weekDays[index],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E0C42)),
                    ),
                    const SizedBox(height: 4),
                    
                    // 상태 점 (색상)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // 수면 시간
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    
                    // [NEW] 점수 표시
                    const SizedBox(height: 2),
                    Text(
                      totalSeconds == 0 ? "-" : "$avgScore점", // 기록 없으면 하이픈
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: totalSeconds == 0 ? Colors.grey.shade300 : const Color(0xFF7A4EC9), // 보라색 포인트
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  // 간단 시간 변환 헬퍼 함수 (ex: 7h 30m)
  String _formatSimpleDuration(int seconds) {
    if (seconds == 0) return '-';
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
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
// --- [UPDATED] 간단 수면 분석 요약 섹션 (실제 데이터 연동) ---
  Widget _buildAnalysisSummarySection(BuildContext context, User? user) {
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
          child: user == null
              ? const Center(child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.white70)))
              : StreamBuilder<QuerySnapshot>(
                  // 최근 10개의 기록을 가져와서 '평소'와 비교합니다.
                  stream: FirebaseFirestore.instance
                      .collection('sleep_records')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('startTime', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // 1. 로딩 중이거나 에러
                    if (snapshot.hasError) return const Text("분석 데이터를 불러올 수 없습니다.", style: TextStyle(color: Colors.white70));
                    if (!snapshot.hasData) return const Text("데이터 분석 중...", style: TextStyle(color: Colors.white70));

                    final docs = snapshot.data!.docs;

                    // 2. 데이터가 없을 때
                    if (docs.isEmpty) {
                      return const Text(
                        "아직 수면 기록이 없습니다.\n오늘 밤 첫 기록을 시작해보세요!",
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                      );
                    }

                    // 3. 데이터 분석 로직
                    // (1) 가장 최신 기록 (지난밤)
                    final lastRecord = docs.first.data() as Map<String, dynamic>;
                    int lastDuration = lastRecord['durationSeconds'] ?? 0;
                    int lastScore = lastRecord['sleepScore'] ?? 0;

                    // (2) 평소 수면 시간 계산 (최신 기록 제외한 나머지들의 평균)
                    String comparisonText = "";
                    if (docs.length > 1) {
                      int totalPastDuration = 0;
                      int count = 0;
                      // docs[1]부터 끝까지 반복
                      for (int i = 1; i < docs.length; i++) {
                        totalPastDuration += (docs[i]['durationSeconds'] as int? ?? 0);
                        count++;
                      }
                      int avgDuration = count > 0 ? totalPastDuration ~/ count : 0;
                      int diff = lastDuration - avgDuration;
                      int diffMin = (diff.abs() ~/ 60); // 분 단위 차이

                      if (diff > 0) {
                        comparisonText = "평소보다 $diffMin분 더 주무셨습니다.";
                      } else {
                        comparisonText = "평소보다 $diffMin분 덜 주무셨습니다.";
                      }
                    } else {
                      comparisonText = "첫 기록이라 비교할 데이터가 없습니다.";
                    }

                    // (3) 수면 점수 기반 멘트 생성
                    String qualityText = "";
                    if (lastScore >= 80) {
                      qualityText = "깊은 수면이 충분하여 수면의 질이 매우 양호합니다.";
                    } else if (lastScore >= 50) {
                      qualityText = "수면 효율은 보통 수준입니다.";
                    } else {
                      qualityText = "수면 질이 다소 낮습니다. 수면 환경을 점검해보세요.";
                    }

                    // (4) 최종 멘트 조합
                    // 예: "지난밤 수면 시간은 7시간 30분으로, 평소보다 15분 더 주무셨습니다. 깊은 수면이 충분하여..."
                    String finalMessage = "지난밤 수면 시간은 ${_formatDurationKorean(lastDuration)}으로, $comparisonText $qualityText";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finalMessage,
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 시간 포맷 헬퍼 함수 (예: 7시간 30분)
  String _formatDurationKorean(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    if (h > 0) return "$h시간 $m분";
    return "$m분";
  } // --- [MODIFIED] 질 좋은 수면을 위한 추천 섹션 (API 연동) ---
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