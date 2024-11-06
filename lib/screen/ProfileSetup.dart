import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'Homepage.dart'; // นำเข้า HomepageScreen

class ProfileSetupScreen extends StatefulWidget {
  final User user;

  ProfileSetupScreen(this.user);

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final formKey = GlobalKey<FormState>();
  String username = '';
  String errorMessage = '';

  Future<void> _checkUsernameAndSave() async {
    final firestore = FirebaseFirestore.instance;
    final usernameRef = firestore.collection('users');

    final querySnapshot = await usernameRef
        .where('username', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        errorMessage = 'ชื่อผู้ใช้นี้ถูกใช้งานแล้ว';
      });
    } else {
      await usernameRef.doc(widget.user.uid).set({
        'username': username,
        'email': widget.user.email,
      });
      Fluttertoast.showToast(
        msg: "ลงทะเบียนสำเร็จ",
        gravity: ToastGravity.CENTER,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomepageScreen(), // นำทางไปยังหน้า HomepageScreen
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ตั้งชื่อผู้ใช้',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อผู้ใช้';
                    }
                    if (value.length < 3) {
                      return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    username = value!;
                  },
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        _checkUsernameAndSave();
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
                      "ยืนยัน",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
