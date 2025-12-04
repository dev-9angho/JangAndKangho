import 'package:flutter/material.dart';

class SleepMusicPage extends StatelessWidget {
  const SleepMusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0C42), // Deep Purple Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0C42),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sleep",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // 1. 카테고리 칩 (Category Chips)
              _buildCategoryList(),
              const SizedBox(height: 30),

              // 2. Featured Section
              _buildSectionTitle("Featured"),
              const SizedBox(height: 15),
              _buildFeaturedList(),

              const SizedBox(height: 30),

              // 3. Popular Section
              const Text(
                "Popular with listeners of",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              _buildSectionTitle("lovely day"), // "lovely day" is highlighted in image
              const SizedBox(height: 15),
              _buildFeaturedList(isSmall: true), // Reusing list but could be different
            ],
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌더 함수들 (Widget Builders) ---

  Widget _buildCategoryList() {
    final categories = ["All", "Sleep stories", "Music", "Mood", "Meditation"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          bool isSelected = category == "All"; // 첫 번째만 선택된 상태로 가정
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E0C42) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          "See all",
          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFeaturedList({bool isSmall = false}) {
    // 더미 데이터 (Dummy Data)
    final items = [
      {
        "title": "Lovely Day",
        "artist": "Austin",
        "duration": "52min",
        "image": "https://picsum.photos/id/1015/300/300", // Placeholder Image
        "color": Colors.teal,
      },
      {
        "title": "Sunday Morning",
        "artist": "Joshua",
        "duration": "36min",
        "image": "https://picsum.photos/id/1016/300/300",
        "color": Colors.orangeAccent,
      },
      {
        "title": "Night Sky",
        "artist": "Sarah",
        "duration": "45min",
        "image": "https://picsum.photos/id/1018/300/300",
        "color": Colors.purpleAccent,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(right: 20),
            width: isSmall ? 140 : 180, // 크기 조절
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 앨범 커버 이미지
                Stack(
                  children: [
                    Container(
                      height: isSmall ? 140 : 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(item["image"] as String),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (item["color"] as Color).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                    ),
                    // 그라데이션 오버레이 (텍스트 가독성용)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 재생 시간 & 버튼
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            item["duration"] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 제목 & 아티스트
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150"), // 프로필 더미
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["title"] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item["artist"] as String,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
