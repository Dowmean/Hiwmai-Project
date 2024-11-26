import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/Regisrecipients.dart';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    email = user?.email ?? '';
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/getUserProfile?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Fetched data: $data");
        setState(() {
          username = data['username'] ?? '';
          gender = data['gender'] ?? 'ไม่ระบุ';
          birthDate = data['birth_date'] ?? '';
          profilePictureUrl = data['profile_picture'] ?? '';
        });
      } else {
        print(
            "Failed to load profile data with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching profile data: $e");
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัวโปรไฟล์
            Container(
              color: Colors.pink,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
            SizedBox(height: 20),
            // การสั่งซื้อของฉัน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'การสั่งซื้อของฉัน',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileOption('ที่ต้องชำระ', Icons.receipt_long),
                      _buildProfileOption('รอจัดส่ง', Icons.local_shipping),
                      _buildProfileOption('ที่ต้องได้รับ', Icons.shopping_bag),
                      _buildProfileOption('ให้คะแนน', Icons.verified),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            // กิจกรรมอื่นๆ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'กิจกรรมอื่นๆ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            builder: (context) => RegisrecipientsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.map, color: Colors.pink, size: 30),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'รายการโปรด',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'คำสั่งซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.pink, size: 30),
        SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.pink)),
      ],
    );
  }
}
