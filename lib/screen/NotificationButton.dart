//ปุ่มแจ้งเตือน
//✅ ใช้ IconButton สำหรับแสดงไอคอนแจ้งเตือน
// ✅ ใช้ IconButton สำหรับแสดงไอคอนแจ้งเตือน
// ✅ มี Badge สีแดง แสดงจำนวนแจ้งเตือนที่ยังไม่ได้อ่าน
// ✅ เมื่อกดปุ่ม จะเปิดหน้า NotificationsPage.dart
// ✅ เมื่อกลับมาที่หน้าเดิม Badge จะอัปเดตอัตโนมัติ
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Notifications.dart';
import 'dart:convert';


class NotificationButton extends StatefulWidget {
  final String email; // รับอีเมลของผู้ใช้ที่ล็อกอิน

  NotificationButton({required this.email});

  @override
  _NotificationButtonState createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  int notificationCount = 0; // จำนวนแจ้งเตือน

  @override
  void initState() {
    super.initState();
    fetchNotificationCount();
  }

  Future<void> fetchNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getNotifications/${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notificationCount = data['notifications'].length; // นับจำนวนแจ้งเตือน
        });
      } else {
        print("Error fetching notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.pink, size: 30), // ✅ ใช้ IconButton
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsPage(email: widget.email),
              ),
            );
            fetchNotificationCount(); // ✅ อัปเดตจำนวนแจ้งเตือนเมื่อกลับมา
          },
        ),
        if (notificationCount > 0) // ✅ แสดง Badge ถ้ามีแจ้งเตือน
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '$notificationCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
