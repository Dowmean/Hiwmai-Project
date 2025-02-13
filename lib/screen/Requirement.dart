import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/RecipientsDetailReq.dart';

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
    final url = 'http://10.0.2.2:3000/getrecipients';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        setState(() {
          users = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบผู้ใช้งานในฐานข้อมูล')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้')),
      );
    }
  }

  Future<void> updateRole(String email) async {
    final url = 'http://10.0.2.2:3000/updateUserRole';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  Future<void> deleteUser(String email) async {
    final url = 'http://10.0.2.2:3000/deleteRecipient';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          users.removeWhere((user) => user['email'] == email);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบข้อมูลนักหิ้วสำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบผู้ใช้ได้')),
        );
      }
    } catch (e) {
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
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                final profilePictureUrl = user['profile_picture'] ?? '';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundImage: profilePictureUrl.isNotEmpty
                          ? NetworkImage(profilePictureUrl)
                          : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
                      radius: 28,
                    ),
                    title: GestureDetector(
                      onTap: () {
                        if (user['firebase_uid'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipientsDetailReqPage(
                                  firebaseUid: user['firebase_uid']),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาด: ไม่มี firebase_uid')),
                          );
                        }
                      },
                      child: Text(
                        user['first_name'] ?? 'ไม่มีชื่อ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => updateRole(user['email']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('ยืนยัน', style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => deleteUser(user['email']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('ลบ', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
