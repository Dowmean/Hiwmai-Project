import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:loginsystem/model/PostModel.dart';
import 'dart:io';

class PostCreate {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.ref().child('product_images/$fileName');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // ฟังก์ชันสำหรับการสร้างโพสต์
  Future<void> createPost({
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    File? imageFile, // รูปภาพจากผู้ใช้ (หากมี)
  }) async {
    User? user = _auth.currentUser; // ดึงข้อมูลผู้ใช้ที่ล็อกอิน
    if (user == null) {
      throw Exception("User not logged in");
    }

    String? imageUrl;

    // อัปโหลดรูปภาพถ้ามี
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    // สร้างข้อมูลโพสต์ใหม่
    PostModel newPost = PostModel(
      userName: user.email!, // ใช้อีเมลของผู้ใช้ที่ล็อกอิน
      userId: user.uid,
      category: category,
      productName: productName,
      productDescription: productDescription,
      price: price,
      imageUrl: imageUrl,
      postedDate: DateTime.now(),
    );

    // บันทึกข้อมูลโพสต์ลง Firestore
    await _firestore.collection('posts').add(newPost.toMap());
    print("Post created successfully");
  }
}

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  File? _selectedImageFile; // ตัวแปรเก็บไฟล์รูปภาพที่ผู้ใช้เลือก

  // ฟังก์ชันนี้จะเรียกเมื่อผู้ใช้กดโพสต์
  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // บันทึกค่าจากฟอร์ม

      try {
        await PostCreate().createPost(
          category: _selectedCategory!,
          productName: _productNameController.text,
          productDescription: _productDescriptionController.text,
          price: double.parse(_priceController.text),
          imageFile: _selectedImageFile, // ส่งไฟล์รูปภาพ (ถ้ามี)
        );
        print("Post submitted successfully");
      } catch (e) {
        print("Error submitting post: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Post")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['เสื้อผ้า', 'รองเท้า', 'ความงาม', 'กระเป๋า']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                decoration: InputDecoration(labelText: 'หมวดหมู่'),
              ),
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              TextFormField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียดสินค้า'),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียดสินค้า' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'ราคาสินค้า (บาท)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกราคา' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPost,
                child: Text("Create Post"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
