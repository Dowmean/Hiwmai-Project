import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:loginsystem/screen/PostCreate.dart';
import 'package:loginsystem/screen/home.dart';  // ตรวจสอบว่าเส้นทางถูกต้อง

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MainApp());
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
      home: HomeScreen(),  // เรียกใช้ HomeScreen เป็นหน้าแรก
      routes: {
        '/createPost': (context) => CreatePostPage(),  // เพิ่มเส้นทางไปยังหน้า CreatePostPage
      },
    );
  }
}
