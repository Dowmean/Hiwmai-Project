import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loginsystem/screen/Myaddress.dart';
import 'package:loginsystem/screen/Mybank.dart';
import 'package:loginsystem/screen/login.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () {
            Navigator.pop(context); // กลับไปหน้าก่อนหน้า
          },
        ),
        title: const Text(
          "ตั้งค่าบัญชี",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // หัวข้อ "บัญชีของฉัน"
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: const Text(
              "บัญชีของฉัน",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          // 🔹 ออกจากระบบ
          ListTile(
            title: const Text("ออกจากระบบ"),
            trailing: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          // 🔹 ไปหน้าที่อยู่ของฉัน
          ListTile(
            title: const Text("ที่อยู่ของฉัน"),
            trailing: const Icon(Icons.location_on, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyAddressScreen()),
              );
            },
          ),
          // 🔹 ไปหน้าข้อมูลบัญชีธนาคาร/บัตร
          ListTile(
            title: const Text("ข้อมูลบัญชีธนาคาร"),
            trailing: const Icon(Icons.credit_card, color: Colors.blue),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBankScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
