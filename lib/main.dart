import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'globals.dart' as globals;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // โหลดภาษาที่บันทึกไว้ก่อนเปิดแอป
  await globals.loadLanguage();     

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookcheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ตั้งค่าสีหลักของทั้งแอปตรงนี้
        colorScheme: ColorScheme.fromSeed(
          seedColor: globals.mainColor, 
          primary: globals.mainColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFCE4EC), // สีพื้นหลังชมพูอ่อนๆ
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      // ระบบ Auto Login
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeScreen(); // ถ้า Login ค้างไว้ ไปหน้า Home เลย
          }
          return const LoginScreen(); // ถ้าไม่ ไปหน้า Login
        },
      ),
    );
  }
}
