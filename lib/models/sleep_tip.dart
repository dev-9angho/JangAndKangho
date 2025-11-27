// lib/models/sleep_tip.dart
// Firebase Functions에서 반환되는 구조화된 JSON 데이터에 대응하는 Dart 모델입니다.

class SleepTip {
  final String title;
  final String summary;
  final String url;

  SleepTip({
    required this.title,
    required this.summary,
    required this.url,
  });

  // JSON Map에서 SleepTip 객체를 생성하는 팩토리 생성자
  factory SleepTip.fromJson(Map<String, dynamic> json) {
    return SleepTip(
      // Functions에서 null이 아님을 보장하지만, 안전하게 처리
      title: json['title'] as String? ?? '제목 없음',
      summary: json['summary'] as String? ?? '요약 없음',
      url: json['url'] as String? ?? 'URL 없음',
    );
  }
}