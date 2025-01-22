//คำขอสมัครเป็นนักหิ้เว
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Chat.dart';

class RequirementPage extends StatefulWidget {
  @override
  _RequirementPageState createState() => _RequirementPageState();
}

class _RequirementPageState extends State<RequirementPage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final url = 'http://10.0.2.2:3000/getrecipients'; // URL ของ API
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body); // แปลง JSON เป็น List
        });
      } else if (response.statusCode == 404) {
        setState(() {
          users = []; // กำหนด users เป็นว่างเปล่า
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบผู้ใช้งานในฐานข้อมูล')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
        );
      }
    } catch (e) {
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้')),
      );
    }
  }

Future<void> updateRole(String email) async {
  final url = 'http://10.0.2.2:3000/updateUserRole'; // URL ของ API
  try {
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      // เคลียร์ข้อมูลใน users list หลังจากอัปเดต role
      setState(() {
        // Remove user from list after role is updated
        users.removeWhere((user) => user['email'] == email);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดต role เป็น Recipient สำเร็จ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถอัปเดต role ได้')),
      );
    }
  } catch (e) {
    print('Error updating role: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
    );
  }
}


Future<void> deleteUser(String email, String firstName) async {
  final url = 'http://10.0.2.2:3000/deleteRecipient'; // URL ของ API
  try {
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      setState(() {
        users.removeWhere((user) => user['email'] == email); // ลบข้อมูลจาก List
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบข้อมูลนักหิ้ว $email สำเร็จ')),
      );

      // Navigate to ChatPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            receiverEmail: email,
            firstName: firstName, // ส่ง firstName ไปยัง ChatPage
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถลบผู้ใช้ $email ได้')),
      );
    }
  } catch (e) {
    print('Error deleting user: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('คำร้องขอเป็นนักหิ้ว', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1),
itemBuilder: (context, index) {
  final user = users[index];
  final profilePictureUrl = user['profile_picture'];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          CircleAvatar(
            backgroundImage: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                ? NetworkImage(profilePictureUrl)
                : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
            radius: 25,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading profile picture: $exception');
            },
          ),
          SizedBox(width: 10),
          Text(
            user['first_name'] ?? 'ไม่มีชื่อ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      Row(
        children: [
          OutlinedButton(
            onPressed: () => updateRole(user['email']),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue, // Text color for confirm
            ),
            child: Text('ยืนยัน'),
          ),
          SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => deleteUser(user['email'], user['first_name'] ?? 'ไม่ทราบชื่อ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('ลบ'),
),

                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}
