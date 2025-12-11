// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'services/firestore_service.dart';
import 'login.dart';
import 'home.dart';
import 'screens/user_onboarding_screen.dart';
import 'app_settings.dart'; // ⭐️ 글로벌 설정

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase 초기화 성공.");
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),   // ⭐️ 추가
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        StreamProvider<User?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, error) {
            debugPrint("인증 스트림 오류: $error");
            return null;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      primaryColor: const Color(0xFF1E0C42),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF1E0C42),
        secondary: const Color(0xFF7A4EC9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E0C42),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardColor: Colors.white,
      useMaterial3: false,
      fontFamily: 'Roboto',
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050509),
      primaryColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7A4EC9),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardColor: const Color(0xFF181818),
      useMaterial3: false,
      fontFamily: 'Roboto',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: settings.t('app_title'),
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: settings.themeMode, // ⭐️ 라이트/다크 모드 전역 적용
      home: const AuthWrapper(),
    );
  }
}

// 사용자 인증 상태 + 온보딩 여부에 따른 화면 분기
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const LoginPage();
    } else {
      return FutureBuilder<bool>(
        future: Provider.of<FirestoreService>(context, listen: false)
            .userProfileExists(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF7A4EC9)),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('데이터 로딩 오류: ${snapshot.error}'),
              ),
            );
          } else if (snapshot.data == true) {
            return const HomePage();
          } else {
            return const UserOnboardingScreen();
          }
        },
      );
    }
  }
}
