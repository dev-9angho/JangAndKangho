// lib/models/sleep_record.dart

class SleepRecord {
  final String weekday;       // "월", "화" ...
  final String bedTime;       // "22:30"
  final String wakeTime;      // "06:30"
  final int totalMinutes;     // 480 처럼 '분' 단위
  final int score;            // 0~100 점수
  final String evaluation;    // "매우 좋음" 등
  final List<String> tips;    // 개선 팁 리스트

  SleepRecord({
    required this.weekday,
    required this.bedTime,
    required this.wakeTime,
    required this.totalMinutes,
    required this.score,
    required this.evaluation,
    required this.tips,
  });

  factory SleepRecord.fromMap(String weekday, Map<String, dynamic> data) {
    return SleepRecord(
      weekday: weekday,
      bedTime: data['bedTime'] as String? ?? '--:--',
      wakeTime: data['wakeTime'] as String? ?? '--:--',
      totalMinutes: data['totalMinutes'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
      evaluation: data['evaluation'] as String? ?? '데이터 없음',
      tips: (data['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  String get totalSleepFormatted {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (totalMinutes <= 0) {
      return '--h --m';
    }
    return '${h}h ${m}m';
  }
}
