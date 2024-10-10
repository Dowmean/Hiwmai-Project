import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loginsystem/model/Profile.dart';
import 'package:loginsystem/screen/home.dart';
import 'package:loginsystem/screen/login.dart';  // เพิ่มการนำเข้า LoginScreen เพื่อใช้กับปุ่มย้อนกลับ

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formkey = GlobalKey<FormState>();
  Profile profile = Profile(email: '', password: '');
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  String errorMessage = ''; // เพิ่มตัวแปรเพื่อเก็บข้อความแสดงข้อผิดพลาด
  bool _isPasswordVisible = false; // เพิ่มการแสดง/ซ่อนรหัสผ่าน

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
            ),
            body: Center(
              child: Text("${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return _buildRegistrationForm();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Loading..."),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildRegistrationForm() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) {
              return const LoginScreen(); // ย้อนกลับไปหน้าเข้าสู่ระบบ
            }));
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Form(
              key: formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ลงทะเบียน',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'อีเมล',
                    style: TextStyle(fontSize: 14, color: Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'กรุณากรอกรูปแบบอีเมลที่ถูกต้อง';
                      }
                      return null;
                    },
                    onSaved: (String? email) {
                      profile.email = email!;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: 'อีเมล',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'รหัสผ่าน',
                    style: TextStyle(fontSize: 14, color: Colors.pink),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (value.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                    onSaved: (String? password) {
                      profile.password = password!;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'รหัสผ่าน',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'สร้างรหัสผ่านที่มีตัวอักษรและตัวเลขอย่างน้อย 6 ตัว',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formkey.currentState!.validate()) {
                          formkey.currentState!.save(); // บันทึกค่าลงใน profile
                          try {
                            await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: profile.email,
                              password: profile.password,
                            )
                                .then((Value) {
                              // เคลียร์ฟอร์มหลังจากลงทะเบียน
                              formkey.currentState!.reset();
                              Fluttertoast.showToast(
                                msg: "ลงทะเบียนสำเร็จ",
                                gravity: ToastGravity.CENTER,
                              );
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) {
                                return HomeScreen();
                              }));
                            });
                            setState(() {
                              profile = Profile(
                                  email: '',
                                  password: ''); // เคลียร์ตัวแปร profile
                              errorMessage =
                                  ''; // รีเซ็ตข้อความข้อผิดพลาดเมื่อสมัครสำเร็จ
                            });
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              errorMessage = e.message ??
                                  'เกิดข้อผิดพลาด'; // จัดการข้อผิดพลาดและแสดงผล
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.pinkAccent, // สีปุ่ม
                      ),
                      child: const Text(
                        "ถัดไป",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) // แสดงข้อความข้อผิดพลาดถ้ามี
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
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
