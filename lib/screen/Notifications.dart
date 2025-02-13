//หน้า แสดงรายการแจ้งเตือนแบบ List เมื่อกดแจ้งเตือน → เปลี่ยนเป็นสถานะ "อ่านแล้ว" 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  final String email;

  NotificationsPage({required this.email});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getNotifications/${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications = data['notifications'];
        });
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  Future<void> markAsRead(int notificationId) async {
    await http.put(
      Uri.parse('http://10.0.2.2:3000/markNotificationRead'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': notificationId}),
    );
    fetchNotifications(); // รีโหลดแจ้งเตือนหลังจากเปลี่ยนสถานะ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      centerTitle: true,
      title: Text("การแจ้งเตือน")),
      body: notifications.isEmpty
          ? Center(child: Text("ไม่มีการแจ้งเตือน"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  title: Text(notification['message']),
                  subtitle: Text(notification['created_at']),
                  trailing: notification['is_read'] == 0
                      ? Icon(Icons.circle, color: Colors.red, size: 10)
                      : null,
                  onTap: () {
                    markAsRead(notification['id']);
                  },
                );
              },
            ),
    );
  }
}
