import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // ใช้สำหรับย่อขนาดภาพ
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ Firebase Authentication

class RegisrecipientsScreen extends StatefulWidget {
  @override
  _RegisrecipientsScreenState createState() => _RegisrecipientsScreenState();
}

class _RegisrecipientsScreenState extends State<RegisrecipientsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for first form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Text editing controllers for second form
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  bool _showSecondForm = false;
  String? _firebaseUid;

    @override
  void initState() {
    super.initState();
    _getFirebaseUid(); // ดึง firebase_uid ของผู้ใช้ที่เข้าสู่ระบบ
  }

  Future<void> _getFirebaseUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _firebaseUid = user?.uid;
    });
    print("Firebase UID: $_firebaseUid"); // Debug: ตรวจสอบค่า firebase_uid
  }

  @override
  void dispose() {
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _selectTitle() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("เลือกคำนำหน้า"),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _titleController.text = 'นางสาว';
                });
                Navigator.pop(context);
              },
              child: Text("นางสาว"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _titleController.text = 'นาย';
                });
                Navigator.pop(context);
              },
              child: Text("นาย"),
            ),
          ],
        );
      },
    );
  }

  void _selectBank() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("เลือกธนาคาร"),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'กรุงไทย';
                });
                Navigator.pop(context);
              },
              child: Text("กรุงไทย"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'กรุงเทพ';
                });
                Navigator.pop(context);
              },
              child: Text("กรุงเทพ"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'กสิกรไทย';
                });
                Navigator.pop(context);
              },
              child: Text("กสิกรไทย"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'ไทยพาณิชย์';
                });
                Navigator.pop(context);
              },
              child: Text("ไทยพาณิชย์"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'ธนชาต';
                });
                Navigator.pop(context);
              },
              child: Text("ธนชาต"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _bankNameController.text = 'ออมสิน';
                });
                Navigator.pop(context);
              },
              child: Text("ออมสิน"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_showSecondForm) {
        
        

final data = {
  "firebase_uid": _firebaseUid,
  "title": _titleController.text,
  "firstName": _firstNameController.text,
  "lastName": _lastNameController.text,
  "phoneNumber": _phoneNumberController.text,
  "address": _addressController.text,
  "bankName": _bankNameController.text,
  "accountName": _accountNameController.text,
  "accountNumber": _accountNumberController.text
};print(data); // ตรวจสอบว่าข้อมูลครบถ้วนก่อนส่งออก



        final response = await http.post(
          Uri.parse("http://10.0.2.2:3000/saveUserData"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
          );
        }
      } else {
        setState(() {
          _showSecondForm = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไขข้อมูลส่วนตัว"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!_showSecondForm) ...[
                Text(
                  "ข้อมูลของผู้รับผลประโยชน์",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _selectTitle,
                  child: AbsorbPointer(
                    child: _buildInputField("คำนำหน้า", _titleController, "กรอกคำนำหน้า"),
                  ),
                ),
                _buildInputField("ชื่อจริง", _firstNameController, "กรอกชื่อจริง"),
                _buildInputField("นามสกุล", _lastNameController, "กรอกนามสกุล"),
                _buildInputField("เบอร์โทรศัพท์", _phoneNumberController, "กรอกเบอร์โทรศัพท์"),
                _buildInputField("ที่อยู่", _addressController, "กรอกที่อยู่", maxLines: 3),
              ] else ...[
                Text(
                  "ข้อมูลธนาคาร",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _selectBank,
                  child: AbsorbPointer(
                    child: _buildInputField("ธนาคาร", _bankNameController, "เลือกธนาคาร"),
                  ),
                ),
                _buildInputField("ชื่อบัญชีธนาคาร", _accountNameController, "กรอกชื่อบัญชี"),
                _buildInputField("หมายเลขบัญชีธนาคาร", _accountNumberController, "กรอกเลขบัญชี"),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  _showSecondForm ? "ยืนยัน" : "ถัดไป",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hintText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอก $label';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
