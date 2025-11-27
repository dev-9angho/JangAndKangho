import 'package:flutter/material.dart';

class SleepAnalysisPage extends StatelessWidget {
  const SleepAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 분석 상세', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E0C42),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          '상세 수면 분석 데이터가 표시될 화면입니다.',
          style: TextStyle(fontSize: 18, color: Color(0xFF1E0C42)),
        ),
      ),
    );
  }
}