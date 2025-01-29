import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loginsystem/model/Profile.dart';
import 'package:loginsystem/screen/Homepage.dart';
import 'package:loginsystem/screen/main.dart';
import 'package:loginsystem/screen/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen(String s, {super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formkey = GlobalKey<FormState>();
  Profile profile = Profile(email: '', password: '');
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  String errorMessage = ''; // ข้อผิดพลาด
  bool _isPasswordVisible = false; // การแสดง/ซ่อนรหัสผ่าน

  // ✅ ฟังก์ชันบันทึกข้อมูลลง MySQL
Future<void> registerUserToDatabase(String firebaseUid, String email) async {
  String firstName = email.split('@')[0]; // ใช้ชื่อจาก email
  final response = await http.post(
    Uri.parse('http://10.0.2.2:3000/api/register'), // ✅ เช็คว่า URL ถูกต้อง
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "firebase_uid": firebaseUid,
      "email": email,
      "first_name": firstName
    }),
  );

  print("Response Code: ${response.statusCode}");
  print("Response Body: ${response.body}"); // ✅ Debug: เช็ค Response

  if (response.statusCode == 200) {
    print("✅ User registered in database successfully");
  } else {
    print("❌ Failed to register user in database: ${response.body}");
  }
}


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
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formkey.currentState!.validate()) {
                          formkey.currentState!.save();
                          try {
                            UserCredential userCredential =
                                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: profile.email,
                              password: profile.password,
                            );

                            // 🔹 ดึง UID ของผู้ใช้
                            String firebaseUid = userCredential.user!.uid;
                            
                            // 🔹 บันทึกลง MySQL
                            await registerUserToDatabase(firebaseUid, profile.email);

                            formkey.currentState!.reset();
                            Fluttertoast.showToast(msg: "ลงทะเบียนสำเร็จ", gravity: ToastGravity.CENTER);
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginScreen();
                            }));
                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              errorMessage = e.message ?? 'เกิดข้อผิดพลาด';
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text(
                        "สมัครบัญชี",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  if (errorMessage.isNotEmpty)
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
