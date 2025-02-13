import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:loginsystem/screen/login.dart';
import 'package:loginsystem/screen/main.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // ✅ สร้าง WebSocket Global Connection
  final websocketChannel = IOWebSocketChannel.connect('ws://10.0.2.2:3000');

  @override
  void initState() {
    super.initState();
    websocketChannel.stream.listen((message) {
      if (message == "reload") {
        print("🔄 รีโหลดข้อมูลทั้งหมด...");
        setState(() {}); // รีโหลด UI ทั้งแอป
      }
    });
  }

  @override
  void dispose() {
    websocketChannel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), 
      routes: {
        '/main': (context) => MainScreen(email: ''), 
      },
    );
  }
}
