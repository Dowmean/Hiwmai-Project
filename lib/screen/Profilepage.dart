import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Regisrecipients.dart';
import 'package:loginsystem/screen/UserList.dart';
import 'package:loginsystem/screen/Requirement.dart';
import 'package:loginsystem/screen/RecipientsList.dart';
import 'ProfileSetting.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String username = '';
  String gender = '';
  String birthDate = '';
  String email = '';
  String profilePictureUrl = '';
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    email = user?.email ?? '';
    _fetchUserData();
    fetchUserRole(email).then((role) {
      setState(() {
        currentUserRole = role;
      });
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getUserProfile?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? '';
          gender = data['gender'] ?? 'ไม่ระบุ';
          birthDate = data['birth_date'] ?? '';
          profilePictureUrl = data['profile_picture'] ?? '';
        });
      } else {
        print("Failed to load profile data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile data: $e");
    }
  }

  Future<String?> fetchUserRole(String email) async {
    final url = 'http://10.0.2.2:3000/getUserRole?email=$email';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['role'];
      } else {
        print('Failed to fetch user role: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  Widget _displayProfileImage() {
    if (profilePictureUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 35,
        backgroundImage: MemoryImage(base64Decode(profilePictureUrl)),
      );
    } else {
      return CircleAvatar(
        radius: 35,
        backgroundImage: AssetImage('assets/avatar.png'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      body: currentUserRole == null
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Container(
                  color: Colors.pink,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _displayProfileImage(),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilesettingScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'แก้ไขโปรไฟล์',
                              style: TextStyle(
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(),
                // ตรวจสอบบทบาทก่อนแสดง UI
                if (currentUserRole == 'Admin') ...[
                  ListTile(
                    title: Text('จัดการบัญชีผู้ใช้งาน'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UserListPage()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('คำร้องขอเป็นนักหิ้ว'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RequirementPage()),
                      );
                    },
                  ),
                  Divider(),
                  // ฟังก์ชันใหม่ "นักหิ้วของฉัน"
                  ListTile(
                    title: Text('นักหิ้วของฉัน'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RecipientsScreen()), // นำไปหน้า RecipientsScreen
                      );
                    },
                  ),
                ],
                Divider(),
                if (currentUserRole != 'Admin')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กิจกรรมอื่นๆ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegisrecipientsScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.map,
                                    color: Colors.pink, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'เริ่มต้นการเป็นนักหิ้ว',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
