import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// ⭐️ 경로 수정
import 'auth_service.dart'; 
import 'login.dart'; // 파일 이름으로 직접 임포트
import 'home.dart'; // 파일 이름으로 직접 임포트

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase 초기화 성공.");
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
  }

  // ⭐️ L30, L33 오류 해결: AuthService 인스턴스 제공 방식 수정
  runApp(
    MultiProvider(
      providers: [
        // AuthService를 ChangeNotifierProvider로 제공
        ChangeNotifierProvider(create: (_) => AuthService()),
        // User 스트림을 StreamProvider로 제공하여 인증 상태 변화를 감지
        StreamProvider<User?>.value(
          // Provider.of<AuthService>(context)를 main에서 직접 사용할 수 없으므로,
          // AuthService 인스턴스를 직접 생성하여 스트림에 전달합니다.
          // AuthService가 싱글톤처럼 동작하지 않으므로 주의가 필요하지만, 
          // 현재 구조에서는 이 방식이 오류를 해결하는 가장 간단한 방법입니다.
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Mate App',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E0C42),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(0xFF1E0C42, {
            50: Color(0xFFE5E0F0),
            100: Color(0xFFBFB0DA),
            200: Color(0x998492C1),
            300: Color(0xFF7A4EC9),
            400: Color(0xFF5B39A3),
            500: Color(0xFF3F267A),
            600: Color(0xFF331F61),
            700: Color(0xFF281849),
            800: Color(0xFF1E0C42), // Primary
            900: Color(0xFF12082B),
          }),
        ).copyWith(secondary: const Color(0xFF7A4EC9)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

// 사용자 인증 상태에 따라 화면을 분기하는 위젯
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider를 통해 현재 User 객체를 가져옵니다.
    final user = Provider.of<User?>(context);

    // ⭐️ L100, L104 오류 해결: HomePage와 LoginPage 클래스 참조
    if (user != null) {
      return const HomePage(); 
    } else {
      return const LoginPage(); 
    }
  }
}