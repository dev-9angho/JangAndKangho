import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; 
import 'services/snore_detection_service.dart';

class SleepRecordingScreen extends StatefulWidget {
  const SleepRecordingScreen({super.key});

  @override
  State<SleepRecordingScreen> createState() => _SleepRecordingScreenState();
}

class _SleepRecordingScreenState extends State<SleepRecordingScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isPaused = true;
  late DateTime _startTime;

  final SnoreDetectionService _aiService = SnoreDetectionService();
  StreamSubscription? _aiSubscription;
  
  int _snoreCount = 0;
  int _sleepTalkCount = 0;
  String _currentSound = "초기화 중...";

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initAI();
  }

  Future<void> _initAI() async {
    // [안전장치 1] 화면 꺼짐 방지 시도 (실패해도 앱은 죽지 않게 try-catch)
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print("⚠️ Wakelock 오류 (무시 가능): $e");
    }

    var status = await Permission.microphone.request();
    if (status.isGranted) {
      // 🚨 [핵심 수정] 타이머를 가장 먼저 시작! (AI 로딩 기다리지 않음)
      print("⏱️ 타이머 강제 시작");
      _startTimer(); 

      // [안전장치 2] 모델 로딩도 try-catch로 감쌈
      try {
        await _aiService.loadModel();
        if (mounted) {
          print("✅ 모델 로딩 완료. 분석 시작.");
          _startAnalysis();
        }
      } catch (e) {
        print("🔴 모델 로딩 실패: $e");
        if (mounted) {
          setState(() => _currentSound = "AI 연결 실패");
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("마이크 권한이 거부되었습니다.")));
      }
    }
  }

  void _startAnalysis() {
    _aiSubscription?.cancel();

    
    _aiSubscription = _aiService.startRecognition().listen((result) {
      String label = result["recognitionResult"].toString();

      if (label.contains("NaN") || label.isEmpty) {
        label = "0 Background Noise";
      }

      if (mounted) {
        setState(() {
          _currentSound = label;
        });
      }

      // 1번: 잠꼬대
      if (label.startsWith('1') || label.contains("잠꼬대")) {
         if (mounted) {
            setState(() {
              _sleepTalkCount++;
              _currentSound = "🗣️ 잠꼬대 감지됨 (녹음 중...)";
            });
         }
      } 
      // 2번: 코골이
      else if (label.startsWith('2') || label.contains("코골이")) {
        if (mounted) {
          setState(() {
            _snoreCount++;
          });
        }
      }
      
    }, onError: (e) {
      print("Error: $e");
      // 에러 나도 1초 뒤 재시도
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isPaused) _startAnalysis();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiSubscription?.cancel();
    _aiService.stopRecognition();
    _aiService.dispose(); 
    WakelockPlus.disable(); 
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

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _aiService.stopRecognition();
    } else {
      _startAnalysis();
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
              _startTimer();
              if (!_isPaused) _startAnalysis();
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

    _aiSubscription?.cancel();
    _aiService.stopRecognition();
    WakelockPlus.disable();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
        if(mounted) Navigator.pop(context);
        return;
    }

    int sleepScore = 100 - (_snoreCount * 2) - (_sleepTalkCount * 1);
    if (sleepScore < 0) sleepScore = 0;

    try {
      if (mounted) {
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white))
        );
      }

      await FirebaseFirestore.instance.collection('sleep_records').add({
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_startTime),
        'endTime': Timestamp.now(),
        'durationSeconds': _secondsElapsed,
        'sleepScore': sleepScore,
        'snoreCount': _snoreCount,
        'sleepTalkCount': _sleepTalkCount,
        'analysisType': 'On-Device AI',
        'hasAudioFile': _sleepTalkCount > 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("수면 기록 저장 완료! (점수: $sleepScore점)")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("저장 에러: $e");
    }
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
              
              Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              
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
                      "AI 분석 상태: $_currentSound", 
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "코골이: $_snoreCount회 | 잠꼬대: $_sleepTalkCount회",
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