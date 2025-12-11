// lib/music.dart
// Calm/Spotify 스타일의 수면 음악 홈 화면 UI + YouTube 인앱 재생

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'music_service.dart';
import 'music_track.dart';

enum SleepCategory {
  all,
  sleepStories,
  music,
  mood,
}

class SleepMusicPage extends StatefulWidget {
  const SleepMusicPage({super.key});

  @override
  State<SleepMusicPage> createState() => _SleepMusicPageState();
}

class _SleepMusicPageState extends State<SleepMusicPage> {
  final MusicService _musicService = MusicService();
  Future<List<MusicTrack>>? _musicTracksFuture;
  MusicTrack? _currentlyPlaying;
  SleepCategory _selectedCategory = SleepCategory.all;

  @override
  void initState() {
    super.initState();
    _fetchMusicRecommendations();
  }

  void _fetchMusicRecommendations() {
    const String userPreferences =
        "30대, 수면 시간 짧음, 잔잔한 음악/백색소음 선호, 스마트폰으로 잠들기 전 음악 재생 습관";

    setState(() {
      _musicTracksFuture =
          _musicService.fetchSleepMusicRecommendations(userPreferences);
    });
  }

  Future<void> _launchYouTubeVideo(MusicTrack track) async {
    if (track.videoUrl.isEmpty || !track.videoUrl.contains('youtube.com')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효한 YouTube URL이 없습니다.')),
        );
      }
      return;
    }

    final Uri uri = Uri.parse(track.videoUrl);

    if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${track.title} 재생 실패: YouTube를 열 수 없습니다.'),
          ),
        );
      }
    } else {
      setState(() => _currentlyPlaying = track);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${track.title}" 재생 시작 (앱 안에서 YouTube 재생)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 카테고리 칩 위젯
  Widget _buildCategoryChips() {
    Widget buildChip(SleepCategory category, String label) {
      final bool selected = _selectedCategory == category;
      return ChoiceChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1A1033) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        selectedColor: Colors.white,
        backgroundColor: const Color(0xFF251749),
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
          // TODO: 실제 카테고리 기반 필터링이 필요하면
          // MusicTrack에 category 필드를 추가하고 여기서 필터링하면 된다.
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip(SleepCategory.all, "All"),
          const SizedBox(width: 8),
          buildChip(SleepCategory.sleepStories, "Sleep stories"),
          const SizedBox(width: 8),
          buildChip(SleepCategory.music, "Music"),
          const SizedBox(width: 8),
          buildChip(SleepCategory.mood, "Mood"),
        ],
      ),
    );
  }

  // 상단 Featured 가로 카드
  Widget _buildFeaturedSection(List<MusicTrack> tracks) {
    final List<MusicTrack> featured =
        tracks.length <= 4 ? tracks : tracks.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "Featured",
          onSeeAll: () {
            // TODO: 전체 보기 페이지 만들면 네비게이션 연결
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final track = featured[index];
              return _buildFeaturedCard(track);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              "See all",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCard(MusicTrack track) {
    final bool isPlaying = _currentlyPlaying?.videoUrl == track.videoUrl;

    return GestureDetector(
      onTap: () => _launchYouTubeVideo(track),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3E2776),
              Color(0xFF281449),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildThumbnail(track),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 48,
                right: 14,
                child: Text(
                  track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 26,
                right: 14,
                child: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Sleep • AI pick",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlaying
                        ? Colors.white
                        : const Color(0xFF281449),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아래쪽 Popular 섹션
  Widget _buildPopularSection(List<MusicTrack> tracks) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    final MusicTrack base =
        _currentlyPlaying ?? tracks.first; // 기준 곡 (타이틀만 문구에 사용)
    final List<MusicTrack> popular = tracks.length > 4
        ? tracks.sublist(2)
        : tracks; // 그냥 나머지 곡들을 popular로 사용

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionHeader(
          title: "Popular with listeners of",
          onSeeAll: () {},
        ),
        const SizedBox(height: 6),
        Text(
          base.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final track = popular[index];
              return _buildSmallCard(track);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard(MusicTrack track) {
    final bool isPlaying = _currentlyPlaying?.videoUrl == track.videoUrl;

    return GestureDetector(
      onTap: () => _launchYouTubeVideo(track),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF24163F),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildThumbnail(track),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? Colors.redAccent
                                : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: isPlaying
                                ? Colors.white
                                : const Color(0xFF24163F),
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF8C6BF4),
                    child: Text(
                      track.artist.isNotEmpty
                          ? track.artist[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 썸네일 로딩 + 플레이스홀더
  Widget _buildThumbnail(MusicTrack track) {
    final bool hasValidUrl =
        track.thumbnailUrl.isNotEmpty && track.thumbnailUrl.startsWith('http');

    if (!hasValidUrl) {
      return _buildThumbnailPlaceholder();
    }

    return Image.network(
      track.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildThumbnailPlaceholder(isLoading: true);
      },
    );
  }

  Widget _buildThumbnailPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3A276E),
            Color(0xFF1F1036),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 34,
              ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<MusicTrack>>(
      future: _musicTracksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF7A4EC9)),
                  SizedBox(height: 16),
                  Text(
                    'AI가 당신을 위한 수면 음악을 고르는 중입니다...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    '음악 추천을 불러오는 중 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchMusicRecommendations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A4EC9),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80.0),
              child: Text(
                '표시할 추천 음악이 없습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final List<MusicTrack> tracks = snapshot.data!;

        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                "Sleep",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              _buildFeaturedSection(tracks),
              _buildPopularSection(tracks),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A2A),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 커스텀 AppBar 영역
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _fetchMusicRecommendations,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 24,
                    ),
                    tooltip: 'AI 추천 새로고침',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
