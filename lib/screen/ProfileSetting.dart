import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ProfilesettingScreen extends StatefulWidget {
  @override
  _ProfilesettingScreenState createState() => _ProfilesettingScreenState();
}

class _ProfilesettingScreenState extends State<ProfilesettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  String gender = 'ไม่ระบุเพศ';
  DateTime? birthDate;
  String email = '';
  File? _profileImage;
  String profileImageUrl = '';
  String? birthDateError;

  @override
  void initState() {
    super.initState();
    email = user?.email ?? '';
    _fetchUserData();
  }

Future<void> _fetchUserData() async {
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/getUserProfile?email=$email'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _usernameController.text = data['username'] ?? '';
        gender = data['gender'] ?? 'ชาย';
        birthDate = DateTime.tryParse(data['birth_date'] ?? '');
        profileImageUrl = data['profile_picture'] ?? '';

        // ตรวจสอบและเพิ่ม Host หาก URL ไม่สมบูรณ์
        if (profileImageUrl.isNotEmpty && !profileImageUrl.startsWith('http')) {
          profileImageUrl = 'http://10.0.2.2:3000$profileImageUrl';
        }
      });
    } else {

    }
  } catch (e) {

  }
}


Widget _displayProfileImage() {
  if (_profileImage != null) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: FileImage(_profileImage!),
    );
  } else if (profileImageUrl.isNotEmpty) {
    // ตรวจสอบว่าเป็น URL หรือ Base64
    if (profileImageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(profileImageUrl), // ใช้ URL
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundImage: MemoryImage(base64Decode(profileImageUrl)), // ใช้ Base64
      );
    }
  } else {
    return CircleAvatar(
      radius: 50,
      backgroundImage: AssetImage('assets/avatar.png'),
    );
  }
}


  Future<void> _updateProfile() async {
    _formKey.currentState!.save(); // บันทึกค่าจาก TextFormField ลงใน username ก่อนอัปเดต

    String? profileImageBase64;
    if (_profileImage != null) {
final bytes = await _profileImage!.readAsBytes();
profileImageBase64 = base64Encode(bytes);

    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/updateUserProfile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'first_name': _usernameController.text, // ดึงค่าจาก TextEditingController
        'gender': gender,
        'birth_date': DateFormat('yyyy-MM-dd').format(birthDate!),
        'profile_picture': profileImageBase64,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      await _fetchUserData(); // ดึงข้อมูลล่าสุดจากฐานข้อมูลเพื่อแสดงค่าที่อัปเดตแล้ว
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile: ${response.body}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('แก้ไขข้อมูลส่วนตัว'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    _displayProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.pink),
                        onPressed: () async {
                          final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (pickedImage != null) {
                            setState(() {
                              _profileImage = File(pickedImage.path);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 20, thickness: 1, color: Colors.grey[300]),
              _buildProfileField('ชื่อผู้ใช้งาน', _usernameController),
              _buildGenderDropdown(),
              _buildBirthDateField(context),
              _buildProfileField('อีเมล', TextEditingController(text: email), enabled: false),
              if (birthDateError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(birthDateError!, style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildGenderDropdown() {
  // Ensure the gender variable has a valid default value
  if (!['ชาย', 'หญิง'].contains(gender)) {
    gender = 'ชาย'; // Default to 'ชาย' if the value is invalid or null
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('เพศ', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: gender,
          onChanged: (String? newValue) {
            setState(() {
              gender = newValue!;
            });
          },
          items: ['ชาย', 'หญิง']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

  Widget _buildBirthDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('วันเกิด', style: TextStyle(fontSize: 16)),
          TextButton(
            onPressed: () => _pickBirthDate(context),
            child: Text(
              birthDate != null ? DateFormat('dd/MM/yyyy').format(birthDate!) : 'เลือกวันเกิด',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );

    if (pickedDate != null) {
      setState(() {
        birthDate = pickedDate;
        birthDateError = null;
      });
    }
  }
}
