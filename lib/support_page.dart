// support_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const String _phoneNumber = '031-0000-0000';
  static const String _email = 'support@sleepmate.app';

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _phoneNumber.replaceAll('-', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=${Uri.encodeComponent('Sleep Mate 앱 문의')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          '고객 문의',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0C42),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Sleep Mate를 사용하시다가 궁금한 점이나 불편한 점이 있다면 언제든지 문의해 주세요.\n\n'
              '빠른 답변을 위해 문의 시 사용 중인 기기, OS 버전, 문제 상황을 함께 남겨주시면 도움이 됩니다.',
              style: TextStyle(
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '연락처',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E0C42),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_in_talk_outlined),
                title: const Text('전화 문의'),
                subtitle: const Text(
                  '031-0000-0000\n문의 가능 시간: 09:00 ~ 18:00 (주말·공휴일 제외)',
                ),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: _callSupport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A4EC9),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('전화 걸기'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('이메일 문의'),
                subtitle: const Text(
                  'support@sleepmate.app\n하루 이내에 답변드릴게요.',
                ),
                isThreeLine: true,
                trailing: TextButton(
                  onPressed: _emailSupport,
                  child: const Text(
                    '메일 보내기',
                    style: TextStyle(color: Color(0xFF7A4EC9)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '자주 묻는 질문',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E0C42),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            children: const [
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('수면 점수는 어떻게 계산되나요?'),
                subtitle: Text('코골이 횟수, 수면 시간 등을 종합적으로 고려하여 산출합니다.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('데이터는 어디에 저장되나요?'),
                subtitle: Text('로그인한 계정 기준으로 안전하게 클라우드에 저장됩니다.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
