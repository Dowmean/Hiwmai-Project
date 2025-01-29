import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loginsystem/screen/login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());

      Fluttertoast.showToast(
        msg: "ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ ${emailController.text.trim()} แล้ว",
        gravity: ToastGravity.CENTER,
        textColor: Colors.green,
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? "เกิดข้อผิดพลาด",
        gravity: ToastGravity.CENTER,
        textColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
const SizedBox(height: 40),
Container(
  width: 80, // ขนาดของวงกลม
  height: 80,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.pinkAccent, // สีขอบ
      width: 2, // ความหนาของเส้นขอบ
    ),
  ),
  child: Center(
    child: Icon(
      Icons.lock,
      size: 40,
      color: Colors.pinkAccent,
    ),
  ),
),
SizedBox(height: 20), // เพิ่มระยะห่าง
                  const Text(
                    "มีปัญหาในการเข้าสู่ระบบใช่ไหม",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ป้อนอีเมลของคุณ แล้วเราจะส่งลิงก์ให้คุณเพื่อกลับเข้าสู่บัญชีผู้ใช้ของคุณ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "กรุณากรอกอีเมล";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "กรุณากรอกรูปแบบอีเมลที่ถูกต้อง";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "อีเมล",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                 
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text(
                        "ยืนยัน",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "ย้อนกลับไปเข้าสู่ระบบ",
                      style: TextStyle(color: Colors.pinkAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
