import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class Article {
  final String title;
  final String subtitle;
  final String category;
  final String? url;

  Article({required this.title, required this.subtitle, required this.category, this.url});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '제목 없음',
      subtitle: json['description'] ?? '',
      category: '실시간 뉴스',
      url: json['url'],
    );
  }
}

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // API 키 확인!
  static const String _apiKey = '0728fb4844ff43fbab7757859083fdfd'; 
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<Article>> getPersonalizedArticles(String userId) async {
    // [1] 함수 시작 확인 로그
    print("🟢 [Debug] 추천 서비스 시작! (UserID: $userId)"); 

    try {
      final snapshot = await _db
          .collection('sleep_records')
          .where('userId', isEqualTo: userId)
          .orderBy('endTime', descending: true)
          .limit(1)
          .get();

      // [2] DB 조회 결과 확인
      if (snapshot.docs.isEmpty) {
        print("🟡 [Debug] DB에 수면 기록이 없습니다. -> 기본 로컬 데이터 반환");
        return _getDefaultArticles(); // 여기서 리턴되어서 API 호출 안 함
      }

      print("🟢 [Debug] 최신 수면 기록 발견! 분석 시작...");
      
      final data = snapshot.docs.first.data();
      final int durationSeconds = data['durationSeconds'] ?? 0;
      final int hours = durationSeconds ~/ 3600;

      print("🟢 [Debug] 수면 시간: $hours 시간 ($durationSeconds 초)");

      // [3] API 호출 시작
      print("🚀 [Debug] NewsAPI 호출 시도..."); 
      List<Article> apiArticles = await _fetchHealthNews();

      if (apiArticles.isNotEmpty) {
        print("✅ [Debug] API 데이터 수신 성공! (${apiArticles.length}개)");
        return apiArticles.take(3).toList();
      } else {
        print("⚠️ [Debug] API 데이터 없음 또는 실패 -> 상황별 로컬 데이터 반환");
      }

      // 상황별 로컬 데이터 (API 실패 시)
      if (hours < 5) return _getInsomniaArticles();
      else if (hours > 9) return _getOversleepArticles();
      else return _getHealthyArticles();

    } catch (e) {
      print("🔥 [Debug] 서비스 에러 발생: $e");
      return _getDefaultArticles();
    }
  }

  Future<List<Article>> _fetchHealthNews() async {
    try {
      // 한국(kr) 건강(health) 뉴스 요청
final url = '$_baseUrl/top-headlines?country=us&category=health&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));

      print("📡 [Debug] API 응답 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'ok') {
          final List<dynamic> articlesJson = data['articles'];
          return articlesJson.map((json) => Article.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("🔥 [Debug] API 네트워크 에러: $e");
      return [];
    }
  }

  // --- 로컬 데이터 ---
  List<Article> _getInsomniaArticles() => [Article(category: "로컬", title: "불면증엔 따뜻한 우유", subtitle: "API 연결 실패/기록 부족")];
  List<Article> _getOversleepArticles() => [Article(category: "로컬", title: "과수면은 피로의 적", subtitle: "API 연결 실패/기록 부족")];
  List<Article> _getHealthyArticles() => [Article(category: "로컬", title: "최적의 수면 습관", subtitle: "API 연결 실패/기록 부족")];
  List<Article> _getDefaultArticles() => [Article(category: "안내", title: "수면 기록이 없습니다", subtitle: "먼저 수면을 기록해주세요")];
}