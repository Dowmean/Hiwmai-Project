import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่ม Firebase Auth
import 'PostService.dart';

class PostCreatePage extends StatefulWidget {
  @override
  _PostCreatePageState createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;
  File? _selectedImageFile;
final TextEditingController _shippingController = TextEditingController();
final TextEditingController _carryController = TextEditingController();

  List<DropdownMenuItem<String>> get _categoryItems {
    return [
      DropdownMenuItem(value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
      DropdownMenuItem(value: 'รองเท้า', child: Text('รองเท้า')),
      DropdownMenuItem(value: 'ความงาม', child: Text('ความงาม')),
      DropdownMenuItem(value: 'กระเป๋า', child: Text('กระเป๋า')),
    ];
  }

  Future<Uint8List?> compressImage(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    if (compressedBytes != null) {
      //("Original size: ${originalBytes.length} bytes");
      //print("Compressed size: ${compressedBytes.length} bytes");
    } else {
      //print("Compression failed");
    }

    return compressedBytes;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File originalFile = File(pickedFile.path);

      //print("Original file path: ${originalFile.path}");

      final Uint8List? compressedBytes = await compressImage(originalFile);

      if (compressedBytes != null) {
        setState(() {
          _selectedImageFile = originalFile; // ใช้ไฟล์ต้นฉบับสำหรับแสดงใน UI
          //print("Image selected successfully");
        });
      } else {
        //print("Image compression failed");
      }
    } else {
      //print("No image selected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่ได้เลือกรูปภาพ')),
      );
    }
  }

Future<void> _submitPost() async {
  if (_selectedCategory == null ||
      _productNameController.text.isEmpty ||
      _priceController.text.isEmpty ||
      _shippingController.text.isEmpty || // ตรวจสอบ shipping
      _carryController.text.isEmpty // ตรวจสอบ carry
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
    );
    return;
  }

  try {
    // ดึง firebase_uid ของผู้ใช้ปัจจุบัน
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }
    final String firebaseUid = user.uid;

    String? base64Image;
    if (_selectedImageFile != null) {
      base64Image = base64Encode(await _selectedImageFile!.readAsBytes());
    }

    // // Log ข้อมูลที่กำลังส่ง
    // print("Submitting data:");
    // print("FirebaseUid: $firebaseUid");
    // print("Category: $_selectedCategory");
    // print("ProductName: ${_productNameController.text}");
    // print("ProductDescription: ${_productDescriptionController.text}");
    // print("Price: ${_priceController.text}");
    // print("Shipping: ${_shippingController.text}");
    // print("Carry: ${_carryController.text}");
    // print("ImageFile: $base64Image");

    // ส่งข้อมูลไปยัง PostService
    await PostService().createPost(
      firebaseUid: firebaseUid, // ส่ง firebase_uid
      category: _selectedCategory!,
      productName: _productNameController.text,
      productDescription: _productDescriptionController.text,
      price: double.parse(_priceController.text),
      shipping: double.parse(_shippingController.text), // ส่ง shipping
      carry: double.parse(_carryController.text), // ส่ง carry
      imageFile: base64Image, // ส่ง Base64 ของรูปภาพ
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('สร้างโพสต์สำเร็จ!')),
    );

    setState(() {
      _productNameController.clear();
      _productDescriptionController.clear();
      _priceController.clear();
      _shippingController.clear();
      _carryController.clear();
      _selectedCategory = null;
      _selectedImageFile = null;
    });
  } catch (e) {
    //print('Error while creating post: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างโพสต์: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("สร้างโพสต์ใหม่"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedImageFile != null)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(_selectedImageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50),
                        SizedBox(height: 10),
                        Text("เพิ่มแคปชั่นและรูปภาพของคุณ",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียดสินค้า'),
                maxLines: 6,
                minLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'ราคา'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
TextFormField(
  controller: _shippingController,
  decoration: InputDecoration(labelText: 'ค่าขนส่ง (Shipping)'),
  keyboardType: TextInputType.number,
),
SizedBox(height: 20),
TextFormField(
  controller: _carryController,
  decoration: InputDecoration(labelText: 'ค่าบริการเพิ่มเติม (Carry)'),
  keyboardType: TextInputType.number,
),

              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categoryItems,
                hint: Text("เลือกหมวดหมู่"),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  child: Text("โพสต์", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
