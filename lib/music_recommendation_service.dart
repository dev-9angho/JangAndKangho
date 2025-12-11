// lib/services/music_recommendation_service.dart
// 이 서비스는 음악 데이터, 검색 기능 및 유튜브 알고리즘을 시뮬레이션한 추천 로직을 관리합니다.

import 'package:flutter/foundation.dart';

// 음악 데이터 모델
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String genre; // 추천을 위한 메타데이터 (예: Ambient, Nature, Lo-Fi)
  final String mood; // 추천을 위한 메타데이터 (예: Calm, Sleep, Focus)
  final String sourceUrl; // 실제 YouTube 또는 다른 플랫폼 URL

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.mood,
    required this.sourceUrl,
  });

  // 임시 Mock 데이터에서 MusicTrack 객체 생성
  factory MusicTrack.fromMap(Map<String, dynamic> data) {
    return MusicTrack(
      id: data['id'] as String,
      title: data['title'] as String,
      artist: data['artist'] as String,
      genre: data['genre'] as String,
      mood: data['mood'] as String,
      sourceUrl: data['sourceUrl'] as String,
    );
  }
}

class MusicRecommendationService extends ChangeNotifier {
  // 실제 음악 데이터를 대신하는 Mock 데이터
  final List<Map<String, dynamic>> _mockMusicData = [
    {
      'id': '1',
      'title': 'Calm Night Piano',
      'artist': 'Sleep Artist',
      'genre': 'Ambient',
      'mood': 'Calm',
      'sourceUrl': 'https://www.youtube.com/watch?v=calmnight',
    },
    {
      'id': '2',
      'title': 'Forest Rain Sound',
      'artist': 'Nature Relax',
      'genre': 'Nature',
      'mood': 'Sleep',
      'sourceUrl': 'https://www.youtube.com/watch?v=rainsound',
    },
    {
      'id': '3',
      'title': 'Lo-Fi Chill Beats',
      'artist': 'Chill Vibe',
      'genre': 'Lo-Fi',
      'mood': 'Focus',
      'sourceUrl': 'https://www.youtube.com/watch?v=loficheck',
    },
    {
      'id': '4',
      'title': 'Deep Relaxation Meditation',
      'artist': 'Meditation Guru',
      'genre': 'Meditation',
      'mood': 'Calm',
      'sourceUrl': 'https://www.youtube.com/watch?v=meditation',
    },
    {
      'id': '5',
      'title': 'Smooth Jazz for Study',
      'artist': 'Jazz Trio',
      'genre': 'Jazz',
      'mood': 'Focus',
      'sourceUrl': 'https://www.youtube.com/watch?v=smoothjazz',
    },
    {
      'id': '6',
      'title': 'Ocean Wave Alpha',
      'artist': 'White Noise',
      'genre': 'Nature',
      'mood': 'Sleep',
      'sourceUrl': 'https://www.youtube.com/watch?v=oceanwave',
    }
  ];

  // 사용자의 청취 기록 (AI 알고리즘의 기초)
  // key: MusicTrack ID, value: 청취 횟수
  final Map<String, int> _listenHistory = {
    '1': 5, // Calm Night Piano를 5번 들음 (가장 좋아하는 장르/무드)
    '3': 2, // Lo-Fi Chill Beats를 2번 들음
  };

  // 모든 트랙 리스트 (Map -> MusicTrack 객체로 변환)
  List<MusicTrack> get allTracks => _mockMusicData.map(MusicTrack.fromMap).toList();

  // --- 1. 검색 기능 ---
  List<MusicTrack> searchMusic(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    
    // 제목, 아티스트, 장르, 무드에서 검색
    final results = allTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
             track.artist.toLowerCase().contains(lowerQuery) ||
             track.genre.toLowerCase().contains(lowerQuery) ||
             track.mood.toLowerCase().contains(lowerQuery);
    }).toList();

    return results;
  }

  // --- 2. 유튜브 알고리즘 기반 추천 기능 (시뮬레이션) ---
  List<MusicTrack> getRecommendedMusic() {
    if (_listenHistory.isEmpty) {
      // 기록이 없으면 인기 트랙 또는 기본 수면 음악 추천
      return allTracks.where((t) => t.mood == 'Sleep' || t.mood == 'Calm').toList();
    }

    // 1. 가장 많이 들은 음악의 무드/장르 파악
    
    // 가장 많이 들은 트랙 ID 찾기
    // reduce를 사용하여 가장 큰 value를 가진 key를 찾습니다.
    String? mostListenedTrackId = _listenHistory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    // 해당 트랙의 정보 찾기
    final mostListenedTrack = allTracks.firstWhere(
      (t) => t.id == mostListenedTrackId,
      orElse: () => allTracks.first, // 오류 방지용 기본값
    );

    final favoriteMood = mostListenedTrack.mood;
    final favoriteGenre = mostListenedTrack.genre;

    // 2. 가장 선호하는 무드/장르와 유사한 트랙 추천
    final recommendations = allTracks.where((track) {
      // 1) 가장 좋아하는 무드와 일치
      bool moodMatch = track.mood == favoriteMood;
      // 2) 가장 좋아하는 장르와 일치
      bool genreMatch = track.genre == favoriteGenre;
      // 3) 이미 많이 들은 곡은 제외 (여기서는 간단히 id가 다른 곡만)
      bool notMostListened = track.id != mostListenedTrackId;
      
      return (moodMatch || genreMatch) && notMostListened;
    }).toList();
    
    // 추천 리스트가 2개 미만이면 Calm 트랙을 추가하여 채움
    if (recommendations.length < 2) {
      final additional = allTracks.where((t) => t.mood == 'Calm' && !recommendations.contains(t)).toList();
      recommendations.addAll(additional);
    }

    // 최대 4개만 반환
    return recommendations.take(4).toList();
  }

  // --- 3. 청취 기록 업데이트 (시뮬레이션 재생 시 호출) ---
  void trackListen(String trackId) {
    _listenHistory.update(
      trackId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    // UI 업데이트를 위해 알림
    notifyListeners();
    if (kDebugMode) {
      print('Track listened: $trackId. Current history: $_listenHistory');
    }
  }
}