import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/snore_detection_service.dart'; // 위에서 만든 서비스 임포트

class SleepRecordingScreen extends StatefulWidget {
  const SleepRecordingScreen({super.key});

  @override
  State<SleepRecordingScreen> createState() => _SleepRecordingScreenState();
}

class _SleepRecordingScreenState extends State<SleepRecordingScreen> {
  // 타이머 관련
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isPaused = false;
  late DateTime _startTime;

  // AI 분석 관련
  final SnoreDetectionService _aiService = SnoreDetectionService();
  StreamSubscription? _aiSubscription; // AI 결과 구독자
  int _snoreCount = 0; // 감지된 코골이 횟수
  String _currentSound = "분석 대기 중..."; // 현재 들리는 소리 (UI 표시용)

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initAI(); // AI 및 타이머 시작
  }

  Future<void> _initAI() async {
    // 마이크 권한 요청
    if (await Permission.microphone.request().isGranted) {
      // 1.타이머 시작

      _startTimer();

      // 2.모델 로드
      // print("🔍 모델 로딩 시도..."); 
      _aiService.loadModel();
      await Future.delayed(const Duration(milliseconds: 1500));
      print("✅ 모델 로딩 완료! 다음 단계로 넘어갑니다.");
      // 3. AI 분석 시작 (구독)
      _startAnalysis();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("마이크 권한이 필요합니다.")));
      }
    }
  }

  void _startAnalysis() {
    _aiSubscription = _aiService.startRecognition().listen((result) {
      // 결과 예시: "Snoring 0.85" (소리종류 확률)
      String label = result["recognitionResult"].toString();
      
      setState(() {
        _currentSound = label; // 화면에 실시간 표시
      });

      // 'Snoring'(코골이) 라벨이 포함되어 있으면 카운트 증가
      // (Teachable Machine에서 라벨 이름을 'Snoring' 또는 '코골이'로 설정해야 함)
      if (label.contains("Snoring") || label.contains("코골이")) {
        setState(() {
          _snoreCount++;
        });
        print("🚨 코골이 감지됨! (총 $_snoreCount회)");
      }
    });
    print("👂 AI가 실시간으로 분석 중입니다...");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiSubscription?.cancel(); // 구독 해제
    _aiService.stopRecognition(); // AI 종료
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  // 일시정지 (AI도 같이 멈춤)
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _aiService.stopRecognition(); // 듣기 중단
    } else {
      _startAnalysis(); // 다시 듣기
    }
  }

  // --- 저장 및 종료 로직 ---
  Future<void> _stopAndSave() async {
    _timer?.cancel();

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수면 종료'),
        content: const Text('분석을 종료하고 결과를 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              _startTimer(); // 취소 시 타이머 재개
              if (!_isPaused) _startAnalysis(); // AI 재개
              Navigator.pop(context, false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장 및 종료', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. AI 완전 종료
    _aiSubscription?.cancel();
    _aiService.stopRecognition();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 2. 점수 계산 (간단 알고리즘)
    // 기본 100점에서 코골이 1회당 1점씩 감점
    int sleepScore = 100 - _snoreCount;
    if (sleepScore < 0) sleepScore = 0;

    try {
      if (mounted) {
        showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white)));
      }

      // 3. Firestore 저장 (파일 경로는 없음!)
      await FirebaseFirestore.instance.collection('sleep_records').add({
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_startTime),
        'endTime': Timestamp.now(),
        'durationSeconds': _secondsElapsed, // [중요] 기존 기능: 수면 시간 저장
        
        // [추가] AI 분석 결과 저장
        'sleepScore': sleepScore,
        'snoreCount': _snoreCount,
        'analysisType': 'On-Device AI', // 분석 방식 표시
        'hasAudioFile': false, // 파일 없음
        
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        Navigator.pop(context); // 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("수면 시간 및 점수($sleepScore점) 저장 완료!")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("저장 에러: $e");
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF2D1B4E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const Spacer(),
              _buildMoonVisual(),
              const SizedBox(height: 50),
              
              // 타이머 표시
              Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              
              // [NEW] 실시간 분석 상태 표시 UI
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "AI 분석 중: $_currentSound", // 예: "Snoring 98%"
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "감지된 코골이: $_snoreCount회",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              _buildControlButtons(),
              const Spacer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- 기존 UI 위젯들 ---
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
          const Text('수면시간', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMoonVisual() {
    return Container(
      width: 280, height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF6A4C93).withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 60, left: 60, child: Icon(Icons.star, size: 12, color: Colors.white30)),
          Icon(Icons.nightlight_round, size: 120, color: const Color(0xFFE0C3FC).withOpacity(0.9)),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(icon: Icons.stop_rounded, color: Colors.redAccent.withOpacity(0.8), onTap: _stopAndSave),
          _buildCircleButton(icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: const Color(0xFF4A306D), size: 80, iconSize: 40, onTap: _togglePause),
          _buildCircleButton(icon: Icons.music_note_rounded, color: Colors.white.withOpacity(0.15), onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onTap, double size=60, double iconSize=30}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}