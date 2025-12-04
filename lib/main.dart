// lib/main.dart (AuthWrapper 수정)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'services/firestore_service.dart'; // ⭐️ 추가
import 'login.dart';
import 'home.dart';
import 'screens/user_onboarding_screen.dart'; // ⭐️ 추가

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // 이 초기화가 성공적으로 이루어져야 합니다.
    await Firebase.initializeApp();
    debugPrint("Firebase 초기화 성공.");
  } catch (e) {
    debugPrint("Firebase 초기화 실패: $e");
    // 초기화 실패 시에도 앱이 실행되도록 합니다.
  }

  runApp(
    MultiProvider(
      providers: [
        // AuthService를 제공하여 앱 전체에서 접근 가능하게 합니다.
        ChangeNotifierProvider(create: (_) => AuthService()),
        // FirestoreService를 제공하여 데이터베이스 접근 가능하게 합니다. ⭐️ 추가
        Provider(create: (_) => FirestoreService()), 
        // User 스트림을 제공하여 인증 상태 변화를 감지합니다.
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep App',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E0C42),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1E0C42),
          secondary: const Color(0xFF7A4EC9),
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', 
      ),
      home: const AuthWrapper(),
    );
  }
}

// 사용자 인증 상태와 온보딩 상태에 따라 화면을 분기하는 위젯
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider를 통해 현재 User 객체를 가져옵니다.
    final user = Provider.of<User?>(context);

    // Firebase Core 초기화가 실패했는지 확인하는 로직 추가
    if (user == null) {
      // 1. 인증 정보가 없으면 로그인 화면으로
      return const LoginPage();
    } else {
      // 2. 인증 정보가 있으면 온보딩 상태 확인
      return FutureBuilder<bool>(
        // FirestoreService를 통해 해당 사용자의 프로필이 존재하는지 확인
        future: Provider.of<FirestoreService>(context, listen: false).userProfileExists(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 로딩 중 (데이터베이스 확인 중)
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF7A4EC9)),
              ),
            );
          } else if (snapshot.hasError) {
            // 오류 발생
            return Scaffold(
              body: Center(
                child: Text('데이터 로딩 오류: ${snapshot.error}'),
              ),
            );
          } else if (snapshot.data == true) {
            // 3. 프로필이 존재하면 홈 화면으로
            return const HomePage();
          } else {
            // 4. 프로필이 존재하지 않으면 온보딩 화면으로 (신규 가입자)
            return const UserOnboardingScreen();
          }
        },
      );
    }
  }
}