import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; // นำเข้า Fluttertoast
import 'package:image_picker/image_picker.dart';
import 'package:loginsystem/screen/PostService.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;
  File? _selectedImageFile;

  // รายการหมวดหมู่
  List<DropdownMenuItem<String>> get _categoryItems {
    return [
      DropdownMenuItem(value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
      DropdownMenuItem(value: 'รองเท้า', child: Text('รองเท้า')),
      DropdownMenuItem(value: 'ความงาม', child: Text('ความงาม')),
      DropdownMenuItem(value: 'กระเป๋า', child: Text('กระเป๋า')),
    ];
  }

  // ฟังก์ชันเลือกภาพจากแกลลอรี่
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
    }
  }

  // ฟังก์ชันสำหรับส่งโพสต์
  void _submitPost() async {
    try {
      await PostService().createPost(
        category: _selectedCategory!,
        productName: _productNameController.text,
        productDescription: _productDescriptionController.text,
        price: double.parse(_priceController.text),
        imageFile: _selectedImageFile, // ส่งไฟล์รูปภาพ (ถ้ามี)
      );
      print("Post submitted successfully");

      // แสดง Fluttertoast เมื่อโพสต์สำเร็จ
      Fluttertoast.showToast(
        msg: "Post created successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // เคลียร์ฟอร์มหลังจากโพสต์สำเร็จ
      setState(() {
        _productNameController.clear();
        _productDescriptionController.clear();
        _priceController.clear();
        _selectedCategory = null;
        _selectedImageFile = null;
      });
    } catch (e) {
      print("Error submitting post: $e");

      // แสดง Fluttertoast เมื่อโพสต์ล้มเหลว
      Fluttertoast.showToast(
        msg: "Failed to create post: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create New Post"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'ชื่อสินค้า'),
              ),
              TextFormField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียดสินค้า'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'ราคา'),
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
              if (_selectedImageFile != null)
                Image.file(
                  _selectedImageFile!,
                  height: 200,
                ),
              TextButton(
                onPressed: _pickImage,
                child: Text("เลือกภาพจากแกลลอรี่"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPost,
                child: Text("โพสต์"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
