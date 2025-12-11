// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('zh'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // 언어별 텍스트 테이블
  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - 홈',
      'settings_title': '설정',
      'general_section': '일반',
      'language': '언어',
      'korean': '한국어',
      'english': '영어',
      'chinese': '중국어',
      'theme': '화면 모드',
      'light_mode': '라이트',
      'dark_mode': '다크',
      'alarm_section': '알림 설정',
      'sleep_alarm_push': '수면 알람 푸시 알림',
      'sleep_alarm_desc': '설정한 취침/기상 시간에 알림을 받습니다.',
      'tips_news_alarm': '수면 팁 & 뉴스 알림',
    },
    'en': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - Home',
      'settings_title': 'Settings',
      'general_section': 'General',
      'language': 'Language',
      'korean': 'Korean',
      'english': 'English',
      'chinese': 'Chinese',
      'theme': 'Theme',
      'light_mode': 'Light',
      'dark_mode': 'Dark',
      'alarm_section': 'Notification',
      'sleep_alarm_push': 'Sleep alarm push',
      'sleep_alarm_desc': 'Get notified at your bedtime / wake-up time.',
      'tips_news_alarm': 'Sleep tips & news',
    },
    'zh': {
      'app_title': 'Sleep Mate',
      'home_title': 'Sleep Mate - 首页',
      'settings_title': '设置',
      'general_section': '通用',
      'language': '语言',
      'korean': '韩语',
      'english': '英语',
      'chinese': '中文',
      'theme': '显示模式',
      'light_mode': '浅色',
      'dark_mode': '深色',
      'alarm_section': '通知设置',
      'sleep_alarm_push': '睡眠提醒推送',
      'sleep_alarm_desc': '在设定的就寝/起床时间收到提醒。',
      'tips_news_alarm': '睡眠小贴士 & 新闻',
    },
  };

  String _text(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['ko']![key] ??
        key;
  }

  String get appTitle => _text('app_title');
  String get homeTitle => _text('home_title');
  String get settingsTitle => _text('settings_title');

  String get generalSection => _text('general_section');
  String get language => _text('language');
  String get korean => _text('korean');
  String get english => _text('english');
  String get chinese => _text('chinese');

  String get theme => _text('theme');
  String get lightMode => _text('light_mode');
  String get darkMode => _text('dark_mode');

  String get alarmSection => _text('alarm_section');
  String get sleepAlarmPush => _text('sleep_alarm_push');
  String get sleepAlarmDesc => _text('sleep_alarm_desc');
  String get tipsNewsAlarm => _text('tips_news_alarm');
}

// LocalizationsDelegate
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ko', 'en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
