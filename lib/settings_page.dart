// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- 일반 섹션 ----------
          Text(
            settings.t('settings_section_general'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          // 언어 카드
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settings.t('settings_language'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: settings.languageCode,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'ko',
                        child: Text(settings.t('settings_language_ko')),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(settings.t('settings_language_en')),
                      ),
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text(settings.t('settings_language_zh')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AppSettings>().setLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 화면 모드 카드 (Light / Dark)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_6),
                      const SizedBox(width: 12),
                      Text(
                        settings.t('settings_theme'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(settings.t('settings_theme_light')),
                        selected:
                            settings.themeMode == ThemeMode.light,
                        onSelected: (_) {
                          context
                              .read<AppSettings>()
                              .setThemeMode(ThemeMode.light);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(settings.t('settings_theme_dark')),
                        selected:
                            settings.themeMode == ThemeMode.dark,
                        onSelected: (_) {
                          context
                              .read<AppSettings>()
                              .setThemeMode(ThemeMode.dark);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 여기 아래로는 알림설정, 버전, 로그아웃, 고객문의 등
          // 카드들을 추가해서 꾸며가면 된다.
        ],
      ),
    );
  }
}
