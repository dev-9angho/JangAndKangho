import 'package:flutter/material.dart';

class SleepStartPage extends StatelessWidget {
  const SleepStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 기록 시작', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E0C42),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          '수면 시작 및 기록 기능이 구현될 화면입니다.',
          style: TextStyle(fontSize: 18, color: Color(0xFF1E0C42)),
        ),
      ),
    );
  }
}