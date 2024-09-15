import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'login.dart';
import 'register.dart';
import 'height_weight.dart';
import 'mainscreen.dart'; // เปลี่ยนจาก main_page.dart เป็น mainscreen.dart
import 'chatgemini.dart';
import 'consts.dart'; // ใช้เพื่อเก็บ GEMINI_API_KEY

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase
  await Firebase.initializeApp();

  // เริ่มต้น Gemini ด้วย API Key
  Gemini.init(apiKey: GEMINI_API_KEY);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/height_weight': (context) => const HeightWeightPage(),
        '/main': (context) =>  MainScreen(),
        
        '/chat': (context) => const ChatGemini(),
      },
      debugShowCheckedModeBanner: false, // ซ่อนแบนเนอร์ debug ที่มุมขวาบน
    );
  }
}
