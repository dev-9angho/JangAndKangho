// lib/app_settings.dart
import 'package:flutter/material.dart';

/// 앱 전체 설정 (언어 + 다크모드) 관리용 ChangeNotifier
class AppSettings extends ChangeNotifier {
  // 언어 코드: 'ko', 'en', 'zh'
  String _languageCode = 'ko';
  ThemeMode _themeMode = ThemeMode.light;

  String get languageCode => _languageCode;
  ThemeMode get themeMode => _themeMode;

  /// 간단한 문자열 번역 테이블
  /// 필요한 키들은 계속 추가하면서 쓰면 된다.
  static const Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - 홈',
      'home_today_sleep': '오늘의 취침',
      'home_tap_to_start': '터치하여 시작하기',
      'home_weekly_pattern': '주간 수면 패턴',
      'home_set_alarm': '수면 알람을 설정하세요',
      'home_set_alarm_button': '알람을 설정해주세요',

      'settings_title': '설정',
      'settings_section_general': '일반',
      'settings_language': '언어',
      'settings_language_ko': '한국어',
      'settings_language_en': '영어',
      'settings_language_zh': '중국어',
      'settings_theme': '화면 모드',
      'settings_theme_light': '라이트',
      'settings_theme_dark': '다크',

      'sleep_title': '수면시간',
      'sleep_ai_waiting': 'AI 분석 대기 중...',
      'sleep_ai_analyzing': 'AI 분석 중',
      'sleep_snore_count': '감지된 코골이',
    },
    'en': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - Home',
      'home_today_sleep': 'Tonight\'s Sleep',
      'home_tap_to_start': 'Tap to start',
      'home_weekly_pattern': 'Weekly Sleep Pattern',
      'home_set_alarm': 'Set your sleep alarm',
      'home_set_alarm_button': 'Please set an alarm',

      'settings_title': 'Settings',
      'settings_section_general': 'General',
      'settings_language': 'Language',
      'settings_language_ko': 'Korean',
      'settings_language_en': 'English',
      'settings_language_zh': 'Chinese',
      'settings_theme': 'Display mode',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',

      'sleep_title': 'Sleep Time',
      'sleep_ai_waiting': 'Waiting for AI analysis...',
      'sleep_ai_analyzing': 'AI analyzing',
      'sleep_snore_count': 'Detected snores',
    },
    'zh': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - 首页',
      'home_today_sleep': '今天的入睡',
      'home_tap_to_start': '点击开始',
      'home_weekly_pattern': '每周睡眠模式',
      'home_set_alarm': '请设置睡眠闹钟',
      'home_set_alarm_button': '请设置闹钟',

      'settings_title': '设置',
      'settings_section_general': '通用',
      'settings_language': '语言',
      'settings_language_ko': '韩语',
      'settings_language_en': '英语',
      'settings_language_zh': '中文',
      'settings_theme': '显示模式',
      'settings_theme_light': '浅色',
      'settings_theme_dark': '深色',

      'sleep_title': '睡眠时间',
      'sleep_ai_waiting': '等待 AI 分析...',
      'sleep_ai_analyzing': 'AI 分析中',
      'sleep_snore_count': '打鼾次数',
    },
  };

  /// 번역 함수: 없는 키면 그냥 키 이름을 그대로 돌려준다.
  String t(String key) {
    final map = _localizedValues[_languageCode] ?? _localizedValues['ko']!;
    return map[key] ?? _localizedValues['ko']![key] ?? key;
  }

  void setLanguage(String code) {
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
