import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:loginsystem/screen/OrderHistory.dart';
import 'package:loginsystem/screen/Ownorder.dart';
import 'package:loginsystem/screen/PaymentComplet.dart';
import 'package:loginsystem/screen/PendingPayment.dart';
import 'package:loginsystem/screen/Receiving.dart';
import 'package:loginsystem/screen/Regisrecipients.dart';
import 'package:loginsystem/screen/Review.dart';
import 'package:loginsystem/screen/Shipping.dart';
import 'package:loginsystem/screen/Topay.dart';
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
      backgroundImage: NetworkImage(profilePictureUrl),
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading profile picture: $exception');
      },
    );
  } else {
    return CircleAvatar(
      radius: 35,
      backgroundImage: AssetImage('assets/avatar.png'),
    );
  }
}
Widget _buildMenuIcon(BuildContext context,
    {required IconData icon, required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.pink.withOpacity(0.1),
          radius: 30,
          child: Icon(icon, color: Colors.pink, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _buildOrderStatusTileWithIcon(
    BuildContext context, IconData icon, String label, Widget destinationPage) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationPage),
      );
    },
    child: Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.pink.withOpacity(0.1),
          radius: 25,
          child: Icon(icon, color: Colors.pink, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
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
                             // แสดงส่วน "สถานะคำสั่งซื้อ" สำหรับทุกบทบาท
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'สถานะคำสั่งซื้อ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderHistoryPage()),
                            );
                            
                          },
                          child: Text(
                            'ดูประวัติคำสั่งซื้อ >',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
                // ตรวจสอบบทบาทก่อนแสดง UI





                //role Admin

           
if (currentUserRole == 'Admin') ...[
  Row(
    mainAxisAlignment: MainAxisAlignment.center, // จัดตำแหน่งให้อยู่ตรงกลาง
    
    children: [
      SizedBox(width: 30),
      // เมนู "ยังไม่ชำระ"
      _buildMenuIcon(
        context,
        icon: Icons.payment,
        label: 'ยังไม่ชำระ',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ToPayOrdersPage()),
          );
        },
      ),
      SizedBox(width: 30), // เพิ่มระยะห่างระหว่างไอคอน
      // เมนู "ชำระเงินเสร็จ"
      // _buildMenuIcon(
      //   context,
      //   icon: Icons.done_all,
      //   label: 'ชำระเงินสำเร็จ',
      //   onTap: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => PaymentCompletedPage()),
      //     );
      //   },
      // ),
      SizedBox(width: 10),
      _buildMenuIcon(
        context,
        icon: Icons.done_all,
        label: 'คำสั่งซื้อสำเร็จ',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentCompletedPage()),
          );
        },
      ),
      SizedBox(width: 10),
      _buildMenuIcon(
        context,
        icon: Icons.done_all,
        label: 'ทำการจ่ายเรียบร้อยแล้ว',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentCompletedPage()),
          );
        },
      ),
    ],
  ),

  Divider(),
  ListTile(
    title: Text('จัดการบัญชีผู้ใช้งาน'),
    trailing: Icon(Icons.manage_accounts), // เปลี่ยนไอคอนเป็น manage_accounts
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserListPage()),
      );
    },
  ),
  Divider(),
  ListTile(
    title: Text('คำร้องขอเป็นนักหิ้ว'),
    trailing: Icon(Icons.request_page), // เปลี่ยนไอคอนเป็น request_page
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RequirementPage()),
      );
    },
  ),
  Divider(),
  // ฟังก์ชันใหม่ "นักหิ้วของฉัน"
  ListTile(
    title: Text('นักหิ้วของฉัน'),
    trailing: Icon(Icons.person_search), // เปลี่ยนไอคอนเป็น person_search
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecipientsScreen()),
      );
    },
  ),
],





// แสดงเฉพาะ Role User
if (currentUserRole == 'User')
  Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'การซื้อของฉัน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        // Row สำหรับเมนู
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // เมนู "ที่ต้องชำระ"
            _buildMenuIcon(
              context,
              icon: Icons.list_alt,
              label: 'ที่ต้องชำระ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PendingPaymentPage(userEmail: '',)),
                );
              },
            ),
            // เมนู "รอจัดส่ง"
            _buildMenuIcon(
              context,
              icon: Icons.local_shipping,
              label: 'รอจัดส่ง',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShippingPage()),
                );
              },
            ),
            // เมนู "ที่ต้องได้รับ"
            _buildMenuIcon(
              context,
              icon: Icons.inbox,
              label: 'ที่ต้องได้รับ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReceivingPage()),
                );
              },
            ),
            // เมนู "ให้คะแนน"
            _buildMenuIcon(
              context,
              icon: Icons.star_border,
              label: 'ให้คะแนน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReviewPage()),
                );
              },
            ),
          ],
        ),
        Divider(),
        // ส่วนกิจกรรมอื่นๆ
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

//role Recipient
if (currentUserRole == 'Recipient') ...[
  Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    _buildOrderStatusTileWithIcon(
      context,
      Icons.pending_actions, // ไอคอนสำหรับสถานะ "ที่ต้องจัดส่ง"
      'ที่ต้องจัดส่ง',
      OrdersPage(), // หน้าปลายทาง
    ),
    _buildOrderStatusTileWithIcon(
      context,
      Icons.local_shipping, // ไอคอนสำหรับสถานะ "กำลังจัดส่ง"
      'กำลังจัดส่ง',
      ShippingPage(), // หน้าปลายทาง
    ),
    _buildOrderStatusTileWithIcon(
      context,
      Icons.check_circle, // ไอคอนสำหรับสถานะ "สำเร็จ"
      'สำเร็จ',
      ReceivingPage(), // หน้าปลายทาง
    ),
    _buildOrderStatusTileWithIcon(
      context,
      Icons.star_border, // ไอคอนสำหรับสถานะ "ให้คะแนน"
      'ให้คะแนน',
      ReviewPage(), // หน้าปลายทาง
    ),
  ],
),


      ],
    ),
  ),
],


              ],
            ),
    );
  }
}
