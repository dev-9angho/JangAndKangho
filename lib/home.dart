import 'package:flutter/material.dart';
import 'package:jangnkangho/sleep_record.dart';
import 'package:lottie/lottie.dart';
import 'music.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import 'sleep_start_page.dart';
import 'sleep_analysis_page.dart';
import 'package:jangnkangho/screens/mypage.dart';
import 'services/recommend_service.dart';
import 'sleep_day_summary_page.dart';
import 'sleep_record.dart';
import 'settings_page.dart';
import 'support_page.dart';
import 'app_settings.dart';
import 'app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 수면 알람 시간 상태
  TimeOfDay? _sleepAlarmTime;

  // 추천 서비스 인스턴스
  final RecommendationService _recommendationService =
      RecommendationService();

  // 알람 설정 Time Picker 띄우기
  Future<void> _selectAlarmTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sleepAlarmTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF7A4EC9),
              onSurface: theme.colorScheme.onSurface,
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
            content: Text(
                '수면 알람을 ${_sleepAlarmTime!.format(context)} (으)로 설정했습니다.'),
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

  // 시간 포맷 변환 함수 (초 → 한글)
  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds초';
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h시간 $m분';
    return '$m분';
  }

  // HH:mm 포맷 (DateTime → "22:30")
  String _formatTimeHM(DateTime? dt) {
    if (dt == null) return '--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // URL 열기 함수
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
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("링크를 열 수 없습니다.")),
        );
      }
    }
  }

  // 특정 요일 카드 클릭 시: 해당 요일 수면 요약 페이지로 이동
  Future<void> _openSleepSummaryForWeekday(
    BuildContext context,
    User user,
    int weekdayIndex, // 0=월, 6=일
    String weekdayLabel,
  ) async {
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final targetDay = monday.add(Duration(days: weekdayIndex));

      final startOfDay =
          DateTime(targetDay.year, targetDay.month, targetDay.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('sleep_records')
          .where('userId', isEqualTo: user.uid)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime', descending: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 요일의 수면 기록이 없습니다.')),
        );
        return;
      }

      int totalSeconds = 0;
      int totalScore = 0;
      int count = 0;
      DateTime? firstBed;
      DateTime? lastWake;

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startTs = data['startTime'] as Timestamp?;
        final endTs = data['endTime'] as Timestamp?;
        final duration = data['durationSeconds'] as int? ?? 0;
        final score = data['sleepScore'] as int? ?? 0;

        totalSeconds += duration;
        totalScore += score;
        count++;

        if (startTs != null) {
          final dt = startTs.toDate();
          if (firstBed == null || dt.isBefore(firstBed)) {
            firstBed = dt;
          }
        }
        if (endTs != null) {
          final dt = endTs.toDate();
          if (lastWake == null || dt.isAfter(lastWake)) {
            lastWake = dt;
          }
        }
      }

      final avgScore = count > 0 ? (totalScore ~/ count) : 0;

      String evaluation;
      if (avgScore >= 80) {
        evaluation = '매우 좋음';
      } else if (avgScore >= 50) {
        evaluation = '보통';
      } else if (avgScore > 0) {
        evaluation = '개선 필요';
      } else {
        evaluation = '데이터 없음';
      }

      final record = SleepRecord(
        weekday: weekdayLabel,
        bedTime: _formatTimeHM(firstBed),
        wakeTime: _formatTimeHM(lastWake),
        totalMinutes: totalSeconds ~/ 60,
        score: avgScore,
        evaluation: evaluation,
        tips: const [],
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SleepDaySummaryPage(record: record),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수면 기록을 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final settings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          settings.t('home_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                (user?.displayName != null &&
                        user!.displayName!.isNotEmpty)
                    ? user.displayName!
                    : (user?.isAnonymous ?? false
                        ? "게스트 사용자"
                        : "일반 사용자"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? "이메일 없음"),
              currentAccountPicture: ClipOval(
              child: Lottie.asset(
                'assets/Lottie.json', // 👈 JSON 파일 경로
                width: 90,                    // 👈 Drawer에 맞게 크기 조정 (선택 사항: 90x90 추천)
                height: 90,                   // 👈 Drawer에 맞게 크기 조정
                fit: BoxFit.cover,
              ),
            ),
              decoration: BoxDecoration(
                color: primary,
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: primary),
              title: const Text('홈', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: Icon(Icons.person, color: primary),
              title: const Text('마이페이지', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: primary),
              title: const Text('수면 분석', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SleepAnalysisPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.music_note, color: primary),
              title: const Text('수면 음악과 테라피',
                  style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SleepMusicPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.share, color: primary),
              title:
                  const Text('나의 수면 패턴 공유', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: primary),
              title: const Text('설정', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.support_agent, color: primary),
              title: const Text('고객 문의', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SupportPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: primary),
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
              _buildSleepStartSection(context, user),
              const SizedBox(height: 30),
              Text(
                settings.t('home_weekly_pattern'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 15),
              _buildWeeklyPatternSection(user),
              const SizedBox(height: 30),
              _buildAlarmSettingSection(context, settings),
              const SizedBox(height: 30),
              _buildAnalysisSummarySection(context, user),
              const SizedBox(height: 30),
              _buildRecommendationSection(context, user),
            ],
          ),
        ),
      ),
    );
  }

  // 중앙 달 모양 섹션
  Widget _buildSleepStartSection(BuildContext context, User? user) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SleepRecordingScreen()),
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
                    color: const Color(0xFF5B39A3).withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
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
            Text(
              settings.t('home_today_sleep'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sleep_records')
                    .where('userId', isEqualTo: user.uid)
                    .where(
                      'endTime',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      ),
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      '기록 불러오기 실패',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        settings.t('home_tap_to_start'),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  int totalSecondsToday = 0;
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    totalSecondsToday +=
                        (data['durationSeconds'] as int? ?? 0);
                  }

                  if (totalSecondsToday == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        settings.t('home_tap_to_start'),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      "${_formatDuration(totalSecondsToday)} 잤어요",
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

  // 주간 수면 패턴 섹션 (점수 표시 + 요일 클릭)
  Widget _buildWeeklyPatternSection(User? user) {
    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sleep_records')
          .where('userId', isEqualTo: user.uid)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .orderBy('startTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("데이터 로딩 실패");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        Map<int, int> weeklyDuration =
            {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        Map<int, int> weeklyScoreSum =
            {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        Map<int, int> weeklyCount =
            {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;
            Timestamp? start = data['startTime'];
            int duration = data['durationSeconds'] ?? 0;
            int score = data['sleepScore'] ?? 0;

            if (start != null) {
              int weekday = start.toDate().weekday;
              weeklyDuration[weekday] =
                  (weeklyDuration[weekday] ?? 0) + duration;
              weeklyScoreSum[weekday] =
                  (weeklyScoreSum[weekday] ?? 0) + score;
              weeklyCount[weekday] =
                  (weeklyCount[weekday] ?? 0) + 1;
            }
          }
        }

        List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 15),
            itemBuilder: (context, index) {
              int weekdayKey = index + 1;
              int totalSeconds = weeklyDuration[weekdayKey] ?? 0;

              int totalScore = weeklyScoreSum[weekdayKey] ?? 0;
              int count = weeklyCount[weekdayKey] ?? 0;
              int avgScore = count > 0 ? (totalScore ~/ count) : 0;

              String timeStr = _formatSimpleDuration(totalSeconds);

              Color statusColor;
              if (totalSeconds == 0) {
                statusColor = Colors.grey.shade300;
              } else if (avgScore >= 80) {
                statusColor = Colors.green.shade400;
              } else if (avgScore >= 50) {
                statusColor = Colors.orange.shade400;
              } else {
                statusColor = Colors.redAccent.shade200;
              }

              final card = Container(
                width: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalSeconds == 0 ? "-" : "$avgScore점",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: totalSeconds == 0
                            ? Colors.grey.shade300
                            : const Color(0xFF7A4EC9),
                      ),
                    ),
                  ],
                ),
              );

              if (totalSeconds == 0) {
                return card;
              }

              return GestureDetector(
                onTap: () {
                  _openSleepSummaryForWeekday(
                    context,
                    user,
                    index,
                    weekDays[index],
                  );
                },
                child: card,
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

  // 수면 알람 설정 섹션
  Widget _buildAlarmSettingSection(
      BuildContext context, AppSettings settings) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    String alarmTimeDisplay = _sleepAlarmTime == null
        ? settings.t('home_set_alarm_button')
        : _sleepAlarmTime!.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          settings.t('home_set_alarm'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF7A4EC9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  alarmTimeDisplay,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _sleepAlarmTime == null
                        ? Colors.grey.shade500
                        : primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _selectAlarmTime(context),
                icon: const Icon(Icons.alarm, color: Colors.white),
                label: const Text(
                  '알람 설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A4EC9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 오늘의 수면 점수 섹션
  Widget _buildAnalysisSummarySection(BuildContext context, User? user) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 수면 점수',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary,
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
              ? const Center(
                  child: Text(
                    "로그인이 필요합니다.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sleep_records')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('startTime', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        "분석 데이터를 불러올 수 없습니다.",
                        style: TextStyle(color: Colors.white70),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Text(
                        "데이터 분석 중...",
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Text(
                        "아직 수면 기록이 없습니다.\n오늘 밤 첫 기록을 시작해보세요!",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      );
                    }

                    final lastRecord =
                        docs.first.data() as Map<String, dynamic>;
                    int lastDuration =
                        lastRecord['durationSeconds'] ?? 0;
                    int lastScore = lastRecord['sleepScore'] ?? 0;

                    String comparisonText = "";
                    if (docs.length > 1) {
                      int totalPastDuration = 0;
                      int count = 0;
                      for (int i = 1; i < docs.length; i++) {
                        totalPastDuration +=
                            (docs[i]['durationSeconds'] as int? ?? 0);
                        count++;
                      }
                      int avgDuration =
                          count > 0 ? totalPastDuration ~/ count : 0;
                      int diff = lastDuration - avgDuration;
                      int diffMin = (diff.abs() ~/ 60);

                      if (diff > 0) {
                        comparisonText =
                            "평소보다 $diffMin분 더 주무셨습니다.";
                      } else {
                        comparisonText =
                            "평소보다 $diffMin분 덜 주무셨습니다.";
                      }
                    } else {
                      comparisonText =
                          "첫 기록이라 비교할 데이터가 없습니다.";
                    }

                    String qualityText = "";
                    if (lastScore >= 80) {
                      qualityText =
                          "깊은 수면이 충분하여 수면의 질이 매우 양호합니다.";
                    } else if (lastScore >= 50) {
                      qualityText =
                          "수면 효율은 보통 수준입니다.";
                    } else {
                      qualityText =
                          "수면 질이 다소 낮습니다. 수면 환경을 점검해보세요.";
                    }

                    String finalMessage =
                        "지난밤 수면 시간은 ${_formatDurationKorean(lastDuration)}으로, $comparisonText $qualityText";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finalMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SleepAnalysisPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                            label: const Text(
                              '자세히 보기',
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

  String _formatDurationKorean(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    if (h > 0) return "$h시간 $m분";
    return "$m분";
  }

  // 질 좋은 수면을 위한 추천 섹션
  Widget _buildRecommendationSection(BuildContext context, User? user) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '질 좋은 수면을 위한 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: user == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("로그인 후 확인 가능합니다."),
                  ),
                )
              : FutureBuilder<List<Article>>(
                  future: _recommendationService
                      .getPersonalizedArticles(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF7A4EC9),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("추천 정보를 불러올 수 없습니다."),
                      );
                    }

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
                          leading: const Icon(
                            Icons.article,
                            color: Color(0xFF7A4EC9),
                          ),
                          title: Text(
                            article.title,
                            style: TextStyle(
                              fontSize: 16,
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            article.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onTap: () {
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
