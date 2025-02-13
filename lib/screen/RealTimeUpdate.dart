import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class RealTimeUpdate extends StatefulWidget {
  @override
  _RealTimeUpdateState createState() => _RealTimeUpdateState();
}

class _RealTimeUpdateState extends State<RealTimeUpdate> {
  final _channel = IOWebSocketChannel.connect('ws://10.0.2.2:3000');

  @override
  void initState() {
    super.initState();

    // ✅ ฟังข้อความจาก Server
    _channel.stream.listen((message) {
      if (message == "reload") {
        print("🔄 Data changed, reloading...");
        setState(() {}); // รีโหลดหน้า
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Real-time Data Update")),
      body: Center(child: Text("Listening for updates...")),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
