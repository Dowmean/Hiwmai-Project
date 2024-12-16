import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:loginsystem/screen/login.dart';
import 'package:loginsystem/screen/main.dart'; // ตรวจสอบว่าเส้นทางถูกต้อง

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,  
      ),
      home: const LoginScreen(),  // เรียกใช้ LoginScreen เป็นหน้าแรก
      routes: {
        '/main': (context) => MainScreen(email: '',), // ตรวจสอบว่าต้องการพารามิเตอร์หรือไม่
      },
    );
  }
}
