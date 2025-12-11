// lib/models/music_track.dart
// Gemini API에서 구조화된 JSON 응답을 위한 Dart 모델입니다.

class MusicTrack {
  final String title;
  final String artist;
  final String thumbnailUrl; // YouTube 썸네일 URL
  final String videoUrl;     // YouTube 영상 URL

  MusicTrack({
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.videoUrl,
  });

  // JSON Map에서 MusicTrack 객체를 생성하는 팩토리 생성자
  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      title: json['title'] as String? ?? '제목 없음',
      artist: json['artist'] as String? ?? '아티스트 없음',
      // 유효하지 않은 URL에 대비하여 기본 플레이스홀더 제공
      thumbnailUrl: json['thumbnailUrl'] as String? ?? 'https://placehold.co/600x400/1E0C42/ffffff?text=No+Image', 
      videoUrl: json['videoUrl'] as String? ?? '', // 비디오 URL이 없으면 빈 문자열
    );
  }
}