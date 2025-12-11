import 'dart:io'; // [추가] 파일 목록 확인용
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart'; // [추가] 경로 확인용
import 'package:audioplayers/audioplayers.dart'; // [추가] 재생용

// 일간 데이터를 다루기 위한 헬퍼 클래스
class DailySleepData {
  final DateTime date;
  final int totalSnore;
  final int avgScore;

  DailySleepData({
    required this.date, 
    required this.totalSnore, 
    required this.avgScore
  });
}

class SleepAnalysisPage extends StatefulWidget {
  const SleepAnalysisPage({super.key});

  @override
  State<SleepAnalysisPage> createState() => _SleepAnalysisPageState();
}

class _SleepAnalysisPageState extends State<SleepAnalysisPage> {
  final user = FirebaseAuth.instance.currentUser;
  final List<String> weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  // [추가] 오디오 플레이어 관련 변수
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath; 

  // [추가] 페이지 종료 시 플레이어 정리
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

Future<List<FileSystemEntity>> _getSleepTalkFiles() async {
  final dir = await getApplicationDocumentsDirectory();
  final List<FileSystemEntity> files = dir.listSync().where((file) {
    // 🚨 확장자 .wav로 수정
    return file.path.endsWith('_highlight.m4a');
  }).toList();

  files.sort((a, b) => b.path.compareTo(a.path));
  return files;
}

  // [추가] 
Future<void> _toggleAudio(String path) async {
    // 🔍 [디버깅용] 파일 크기 확인 코드
    final file = File(path);
    if (await file.exists()) {
      final size = await file.length();
      print("📂 재생 파일 경로: $path");
      print("📏 파일 크기: $size bytes"); // 이 로그를 확인하세요!
      
      if (size < 1000) {
        print("⚠️ 파일이 너무 작습니다! 녹음이 제대로 안 된 것 같습니다.");
        return; // 재생 안 함
      }
    } else {
      print("❌ 파일이 존재하지 않습니다.");
      return;
    }
  try {
    if (_playingPath == path) {
      await _audioPlayer.stop();
      setState(() => _playingPath = null);
    } else {
      await _audioPlayer.stop();

      // 🔊 볼륨 최대로 설정
      await _audioPlayer.setVolume(1.0); 

      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _playingPath = path);

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingPath = null);
      });
    }
  } catch (e) {
    print("재생 오류: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF7A4EC9), width: 1.5),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1A1A2E),
          ),
          child: const Text(
            "수면 분석",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sleep_records')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('startTime', descending: true) 
                  .limit(30) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("분석할 데이터가 없습니다.", style: TextStyle(color: Colors.white54)));
                }

                // --- 1. 날짜별 데이터 그룹화 및 합산 로직 ---
                Map<String, List<Map<String, dynamic>>> groupedData = {};

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  Timestamp? timestamp = data['startTime'];
                  if (timestamp == null) continue;
                  
                  DateTime dt = timestamp.toDate();
                  String dateKey = "${dt.year}-${dt.month}-${dt.day}";

                  if (groupedData[dateKey] == null) {
                    groupedData[dateKey] = [];
                  }
                  groupedData[dateKey]!.add(data);
                }

                List<DailySleepData> dailyList = [];
                groupedData.forEach((key, records) {
                  int totalSnore = 0;
                  int totalScoreSum = 0;

                  for (var record in records) {
                    totalSnore += (record['snoreCount'] as int? ?? 0);
                    totalScoreSum += (record['sleepScore'] as int? ?? 0);
                  }

                  int avgScore = records.isNotEmpty ? totalScoreSum ~/ records.length : 0;
                  
                  List<String> parts = key.split('-');
                  DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

                  dailyList.add(DailySleepData(date: date, totalSnore: totalSnore, avgScore: avgScore));
                });

                dailyList.sort((a, b) => b.date.compareTo(a.date));

                // --- 2. 비교 분석 멘트 생성 ---
                String scoreComparisonText = "데이터가 부족합니다.";
                String snoreComparisonText = "데이터가 부족합니다.";

                if (dailyList.length >= 2) {
                  DailySleepData latest = dailyList[0];
                  DailySleepData previous = dailyList[1];

                  int diffScore = latest.avgScore - previous.avgScore;
                  if (diffScore > 0) {
                    scoreComparisonText = "직전 기록보다 평균 수면 점수가 $diffScore점 올랐어요! 🚀";
                  } else if (diffScore < 0) {
                    scoreComparisonText = "직전 기록보다 평균 점수가 ${diffScore.abs()}점 떨어졌어요. 😢";
                  } else {
                    scoreComparisonText = "직전 기록과 평균 점수가 같습니다.";
                  }

                  int diffSnore = latest.totalSnore - previous.totalSnore;
                  if (diffSnore > 0) {
                      snoreComparisonText = "직전보다 코골이가 총 $diffSnore회 늘었습니다.";
                  } else if (diffSnore < 0) {
                      snoreComparisonText = "직전보다 코골이가 총 ${diffSnore.abs()}회 줄었습니다! 👍";
                  } else {
                      snoreComparisonText = "코골이 횟수가 지난번과 같습니다.";
                  }
                } else if (dailyList.isNotEmpty) {
                  scoreComparisonText = "첫 기록이네요! 내일 비교 분석을 확인해보세요.";
                  snoreComparisonText = "오늘 밤 편안한 수면 되세요.";
                }

                // --- 3. 차트용 데이터 매핑 ---
                Map<int, int> chartScoreMap = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};
                Map<int, int> chartSnoreMap = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0};

                for (var dayData in dailyList) {
                  int weekday = dayData.date.weekday;
                  if (chartScoreMap[weekday] == 0) chartScoreMap[weekday] = dayData.avgScore;
                  if (chartSnoreMap[weekday] == 0) chartSnoreMap[weekday] = dayData.totalSnore;
                }

                int maxSnoreCount = 0;
                for (var count in chartSnoreMap.values) {
                  if (count > maxSnoreCount) maxSnoreCount = count;
                }
                double dynamicMaxY = maxSnoreCount > 0 ? (maxSnoreCount + 5).toDouble() : 20.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      const Text("주간 수면 품질 (일 평균)", 
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      _buildLineChartCard(chartScoreMap),
                      
                      const SizedBox(height: 20),
                      _buildInsightBubble(scoreComparisonText, Icons.insights),

                      const SizedBox(height: 40),

                      const Text("요일별 총 코골이 횟수", 
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      _buildBarChartCard(chartSnoreMap, dynamicMaxY),

                      const SizedBox(height: 20),
                      _buildInsightBubble(snoreComparisonText, Icons.mic_none),

                      // ----------------------------------------------------
                      // [추가] 잠꼬대 리스트 섹션
                      // ----------------------------------------------------
                      const SizedBox(height: 40),
                      const Text("감지된 잠꼬대 기록 🎙️", 
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      _buildSleepTalkList(), // 아래에 정의된 함수 호출

                      const SizedBox(height: 40), // 바닥 여백
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- [추가] 잠꼬대 리스트 빌더 함수 ---
  Widget _buildSleepTalkList() {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _getSleepTalkFiles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF252540),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("아직 기록된 잠꼬대가 없습니다.", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final file = snapshot.data![index];
            final fileName = file.path.split('/').last;
            final timestampStr = fileName.split('_')[0];
            final dateTime = DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestampStr) ?? 0);
            final dateStr = "${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2,'0')}";
            
            final isPlaying = _playingPath == file.path;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF252540),
                borderRadius: BorderRadius.circular(15),
                border: isPlaying ? Border.all(color: const Color(0xFF7A4EC9), width: 1.5) : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPlaying ? const Color(0xFF7A4EC9) : Colors.white10,
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                ),
                title: Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("잠꼬대 의심 (5초)", style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await file.delete();
                    setState(() {}); 
                  },
                ),
                onTap: () => _toggleAudio(file.path),
              ),
            );
          },
        );
      },
    );
  }

  // --- 기존 차트 위젯들 ---

  Widget _buildLineChartCard(Map<int, int> dataMap) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252540), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(weekDays[index], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white30, fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: 6,
          minY: 0, maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(7, (index) {
                double score = (dataMap[index + 1] ?? 0).toDouble();
                return FlSpot(index.toDouble(), score);
              }),
              isCurved: true,
              color: const Color(0xFF7A4EC9),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFD0BCFF),
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF7A4EC9),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF7A4EC9).withOpacity(0.15), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(Map<int, int> dataMap, double maxY) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252540),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY, 
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weekDays[value.toInt()],
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            double count = (dataMap[index + 1] ?? 0).toDouble();
            Color barColor = count > 0 ? const Color(0xFFFF8E8E) : Colors.white10;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count == 0 ? 1 : count, 
                  color: barColor,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY, 
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsightBubble(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B2A68), Color(0xFF2A1F45)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFD0BCFF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}