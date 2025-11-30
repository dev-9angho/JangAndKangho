import 'dart:async';
import 'dart:ui'; // For FontFeature
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SleepRecordingScreen extends StatefulWidget {
  const SleepRecordingScreen({super.key});

  @override
  State<SleepRecordingScreen> createState() => _SleepRecordingScreenState();
}

class _SleepRecordingScreenState extends State<SleepRecordingScreen> {
  // Timer State
  Timer? _timer;
  int _secondsElapsed = 0; // Starts from 0
  bool _isPaused = false;
  
  // Record Data
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now(); // Record start time when screen opens
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
  }

  // --- SAVE LOGIC (핵심 저장 로직) ---
  Future<void> _stopAndSave() async {
    _timer?.cancel(); // Stop timer temporarily

    // 1. Confirm Dialog (실수 방지용 확인창)
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수면 종료'),
        content: const Text('수면을 종료하고 기록을 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              _startTimer(); // Resume timer if cancelled
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

    // 2. Prepare Data
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    final endTime = DateTime.now();
    
    // 3. Save to Firestore
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      await FirebaseFirestore.instance.collection('sleep_records').add({
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_startTime),
        'endTime': Timestamp.fromDate(endTime),
        'durationSeconds': _secondsElapsed,
        'createdAt': FieldValue.serverTimestamp(), // For sorting
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close Recording Screen -> Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("편안한 밤 되셨나요? 수면 기록이 저장되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading if error
      print("Error saving sleep record: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
              
              // Timer Text
              Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(height: 50),
              _buildControlButtons(),
              const Spacer(),
              // Bottom Navigation Bar Removed (하단 바 제거됨)
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
          const Text(
            '수면시간',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMoonVisual() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.01),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4C93).withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 60, left: 60, child: Icon(Icons.star, size: 12, color: Colors.white30)),
          const Positioned(bottom: 80, right: 60, child: Icon(Icons.star, size: 10, color: Colors.white24)),
          Icon(Icons.nightlight_round, size: 120, color: const Color(0xFFE0C3FC).withOpacity(0.9)),
          Positioned(
            bottom: 60,
            left: 50,
            child: Icon(Icons.cloud, size: 100, color: const Color(0xFF9F86C0).withOpacity(0.7)),
          ),
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
          // Stop Button (Saves Data)
          _buildCircleButton(
            icon: Icons.stop_rounded,
            color: Colors.redAccent.withOpacity(0.8), // Red to indicate Stop
            onTap: _stopAndSave,
          ),
          
          // Pause/Resume Button
          _buildCircleButton(
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: const Color(0xFF4A306D),
            size: 80,
            iconSize: 40,
            onTap: _togglePause,
          ),
          
          // Music Button (Placeholder)
          _buildCircleButton(
            icon: Icons.music_note_rounded,
            color: Colors.white.withOpacity(0.15),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("음악 재생 기능은 준비 중입니다."))
               );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 60,
    double iconSize = 30,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}