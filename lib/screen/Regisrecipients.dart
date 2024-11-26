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
  final TextEditingController _accountTypeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Text editing controllers for second form
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  bool _isVATRegistered = false;
  File? _idCardImage;

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
    _accountTypeController.dispose();
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _idCardImage = File(pickedImage.path);
      });
    }
  }

Future<String?> _resizeAndConvertImage(File imageFile) async {
  final originalImage = img.decodeImage(await imageFile.readAsBytes());

  // ย่อขนาดภาพให้กว้าง 300 พิกเซล และลดคุณภาพให้เหลือ 70%
  final resizedImage = img.copyResize(originalImage!, width: 300);

  // แปลงภาพที่ย่อขนาดแล้วเป็น Base64 ด้วยคุณภาพที่ต่ำลง
  return base64Encode(img.encodeJpg(resizedImage, quality: 70)); // ลดคุณภาพเป็น 70%
}


  void _selectAccountType() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("เลือกประเภทบัญชี"),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _accountTypeController.text = 'บุคคลทั่วไป';
                });
                Navigator.pop(context);
              },
              child: Text("บุคคลทั่วไป"),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _accountTypeController.text = 'นิติบุคคลภายในประเทศ';
                });
                Navigator.pop(context);
              },
              child: Text("นิติบุคคลภายในประเทศ"),
            ),
          ],
        );
      },
    );
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
        // ย่อขนาดและแปลงภาพบัตรประชาชนเป็น Base64
        final base64Image = _idCardImage != null ? await _resizeAndConvertImage(_idCardImage!) : null;

final data = {
  "firebase_uid": _firebaseUid,
  "accountType": _accountTypeController.text,
  "title": _titleController.text,
  "firstName": _firstNameController.text,
  "lastName": _lastNameController.text,
  "phoneNumber": _phoneNumberController.text,
  "address": _addressController.text,
  "bankName": _bankNameController.text,
  "accountName": _accountNameController.text,
  "accountNumber": _accountNumberController.text,
  "taxId": _taxIdController.text,
  "idCardImage": base64Image, // ตรวจสอบให้เป็น Base64 string
  "vatRegistered": _isVATRegistered
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
                  onTap: _selectAccountType,
                  child: AbsorbPointer(
                    child: _buildInputField("ประเภทบัญชี", _accountTypeController, "กรอกประเภทบัญชี"),
                  ),
                ),
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
                  "ข้อมูลธนาคารและภาษี",
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
                _buildInputField("เลขประจำตัวผู้เสียภาษี", _taxIdController, "กรอกเลขประจำตัวผู้เสียภาษี"),
                SizedBox(height: 20),
                Text("บัตรประจำตัวประชาชน", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    color: Colors.grey[200],
                    height: 150,
                    width: double.infinity,
                    child: _idCardImage == null
                        ? Center(child: Text("คลิกเพื่อถ่ายภาพบัตรประชาชน"))
                        : Image.file(_idCardImage!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text("คุณทำการจดทะเบียนภาษีหรือไม่?", style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: _isVATRegistered,
                          onChanged: (value) {
                            setState(() {
                              _isVATRegistered = value as bool;
                            });
                          },
                        ),
                        Text("ใช่"),
                        Radio(
                          value: false,
                          groupValue: _isVATRegistered,
                          onChanged: (value) {
                            setState(() {
                              _isVATRegistered = value as bool;
                            });
                          },
                        ),
                        Text("ไม่"),
                      ],
                    ),
                  ],
                ),
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
