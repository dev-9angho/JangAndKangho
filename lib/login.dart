import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// 사용자의 인증 상태를 실시간으로 감지하여
/// 로그인 화면 또는 홈 화면을 보여주는 위젯입니다.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 데이터가 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // 유저가 로그인된 상태라면 홈 화면으로
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        // 로그인이 안 된 상태라면 로그인 화면으로
        return const LoginPage();
      },
    );
  }
}

//구글 login 
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 구글 로그인 프로세스를 처리합니다.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. 구글 로그인 흐름 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 창을 닫았을 때
        return null; 
      }

      // 2. 인증 세부 정보 요청
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase용 새 자격 증명 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. 자격 증명으로 Firebase 로그인
      return await _auth.signInWithCredential(credential);
      
    } catch (e) {
      debugPrint("로그인 에러 발생: $e");
      return null;
    }
  }

  /// 로그아웃을 처리합니다.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // 구글 계정 로그아웃
      await _auth.signOut(); // Firebase 로그아웃
    } catch (e) {
      debugPrint("로그아웃 에러 발생: $e");
    }
  }
}

/// 로그인 화면 UI
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("구글로 로그인"),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  
                  // AuthService를 통해 로그인 시도
                  await AuthService().signInWithGoogle();
                  
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
      ),
    );
  }
}

/// 로그인 성공 후 보여질 홈 화면 UI
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자 정보 가져오기
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("홈 화면"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 로그아웃 실행
              await AuthService().signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            const SizedBox(height: 20),
            Text(
              "환영합니다, ${user?.displayName ?? '사용자'}님!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${user?.email}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}