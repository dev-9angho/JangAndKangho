// lib/services/music_service.dart
// Gemini API와 Google Search Grounding을 사용하여 YouTube 음악을 추천받는 서비스

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'music_track.dart';

class MusicService {
  // ⚠️ Flutter Web 환경에서 API 키를 설정해야 합니다. 현재는 빈 문자열로 둡니다.
  final String _apiKey =
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: "");
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent";

  Future<List<MusicTrack>> fetchSleepMusicRecommendations(
      String userPreferences) async {
    // API 키가 없는 경우 mock 데이터 반환
    if (_apiKey.isEmpty) {
      debugPrint(
          "MusicService: GEMINI_API_KEY 가 비어있습니다. 데모용 Mock 트랙을 반환합니다.");
      return _createMockTracks();
    }

    // AI에게 요청할 시스템 명령어: 수면 음악을 YouTube에서 찾아 구조화된 JSON으로 반환
    const String systemPrompt =
        "당신은 숙면을 위한 음악을 추천하는 전문가입니다. "
        "사용자의 수면 프로필과 선호도를 기반으로 YouTube에서 잔잔한 수면 유도 음악, 백색 소음, 또는 ASMR 10개를 검색하고, "
        "각 음악의 제목(title), 채널/아티스트(artist), 유효한 YouTube 비디오 URL(videoUrl), "
        "그리고 썸네일 URL(thumbnailUrl, 이미지 URL)을 포함하는 JSON 배열을 생성하여 반환하세요. "
        "응답은 반드시 JSON 형식이어야 하며, 마크다운 텍스트나 추가 설명은 포함하지 마세요.";

    // 사용자가 AI에게 전달할 구체적인 검색 쿼리
    final String userQuery = "사용자 프로필: $userPreferences. "
        "이 프로필에 가장 잘 맞는 수면 음악을 유튜브에서 10개 추천해주세요. "
        "검색어 예시: 'healing sleep music', 'calm piano for sleep', 'white noise for deep sleep'.";

    // 응답 스키마 정의: List<MusicTrack>에 매칭됨
    final Map<String, dynamic> responseSchema = {
      "type": "ARRAY",
      "items": {
        "type": "OBJECT",
        "properties": {
          "title": {"type": "STRING", "description": "음악 제목"},
          "artist": {
            "type": "STRING",
            "description": "아티스트 또는 유튜브 채널 이름"
          },
          "thumbnailUrl": {
            "type": "STRING",
            "description": "유효한 YouTube 썸네일 이미지 URL"
          },
          "videoUrl": {
            "type": "STRING",
            "description":
                "유효한 YouTube 비디오 URL (예: https://www.youtube.com/watch?v=...)"
          },
        },
        "required": ["title", "artist", "thumbnailUrl", "videoUrl"],
      }
    };

    final Map<String, dynamic> payload = {
      "contents": [
        {
          "parts": [
            {"text": userQuery}
          ]
        }
      ],
      "tools": [
        {
          "google_search": {},
        }
      ],
      "systemInstruction": {
        "parts": [
          {"text": systemPrompt}
        ]
      },
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": responseSchema,
      }
    };

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        // JSON 응답의 텍스트 부분을 추출
        final String jsonText =
            result['candidates']?[0]['content']['parts'][0]['text']
                    as String? ??
                '[]';

        final List<dynamic> jsonList = json.decode(jsonText);
        return jsonList
            .map((item) => MusicTrack.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint(
            "MusicService: API 호출 실패 (status: ${response.statusCode}). body: ${response.body}");
        // API 호출 실패 시에도 앱이 죽지 않도록 Mock 데이터로 대체
        return _createMockTracks();
      }
    } catch (e, stackTrace) {
      debugPrint("MusicService: API 호출 중 예외 발생: $e");
      debugPrint("$stackTrace");
      // 네트워크 오류 등 예외 상황에서도 Mock 데이터 반환
      return _createMockTracks();
    }
  }

  /// 데모/로컬 개발용 Mock 트랙
  /// 실제 배포 시에는 Gemini 또는 서버 측 추천 로직으로 대체 가능
  List<MusicTrack> _createMockTracks() {
    // YouTube 비디오 ID들을 사용해서 썸네일 URL을 만들면
    // 이미지 깨짐 가능성이 훨씬 줄어든다.
    const demoVideoId1 = "jfKfPfyJRdk"; // 예: lofi/relax 라이브 스트림 (데모용)
    const demoVideoId2 = "5qap5aO4i9A"; // 예: relax/study 음악 (데모용)

    final List<MusicTrack> tracks = [
      MusicTrack(
        title: "Demo Sleep Track 1",
        artist: "YouTube Sample",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId1/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId1",
      ),
      MusicTrack(
        title: "Demo Sleep Track 2",
        artist: "YouTube Sample",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId2/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId2",
      ),
      MusicTrack(
        title: "Soft Ambient Demo",
        artist: "Sleep Channel A",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId1/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId1",
      ),
      MusicTrack(
        title: "Calm Night Demo",
        artist: "Sleep Channel B",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId2/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId2",
      ),
      MusicTrack(
        title: "Rainy Window Demo",
        artist: "Nature Sounds Demo",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId1/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId1",
      ),
      MusicTrack(
        title: "White Noise Demo",
        artist: "ASMR Demo",
        thumbnailUrl:
            "https://img.youtube.com/vi/$demoVideoId2/hqdefault.jpg",
        videoUrl: "https://www.youtube.com/watch?v=$demoVideoId2",
      ),
    ];

    // 입장할 때마다 순서를 섞어서 "랜덤하게 보이는" 효과
    tracks.shuffle();
    return tracks;
  }
}
