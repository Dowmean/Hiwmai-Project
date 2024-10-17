import 'dart:io';
import 'package:flutter/material.dart';
import 'image_util.dart'; // สำหรับการ resize รูปภาพ
import 'PostService.dart'; // สำหรับการเชื่อมต่อกับการสร้างโพสต์

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

  // ตัวเลือกหมวดหมู่
  List<DropdownMenuItem<String>> get _categoryItems {
    return [
      DropdownMenuItem(value: 'เสื้อผ้า', child: Text('เสื้อผ้า')),
      DropdownMenuItem(value: 'รองเท้า', child: Text('รองเท้า')),
      DropdownMenuItem(value: 'ความงาม', child: Text('ความงาม')),
      DropdownMenuItem(value: 'กระเป๋า', child: Text('กระเป๋า')),
    ];
  }

  // เลือกรูปภาพจากแกลลอรี่และทำการ resize
  Future<void> _pickImage() async {
    File? resizedImage = await pickAndResizeImage(); // ใช้ฟังก์ชัน resize
    if (resizedImage != null) {
      setState(() {
        _selectedImageFile = resizedImage;
      });
    }
  }

  // ฟังก์ชันส่งโพสต์ไปยังเซิร์ฟเวอร์
  void _submitPost() async {
    if (_selectedCategory == null || _productNameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    try {
      await PostService().createPost(
        category: _selectedCategory!,
        productName: _productNameController.text,
        productDescription: _productDescriptionController.text,
        price: double.parse(_priceController.text),
        imageFile: _selectedImageFile, // ส่งรูปภาพ (ที่ถูก resize แล้ว)
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างโพสต์สำเร็จ!')),
      );

      // รีเซ็ตข้อมูลหลังจากการโพสต์
      setState(() {
        _productNameController.clear();
        _productDescriptionController.clear();
        _priceController.clear();
        _selectedCategory = null;
        _selectedImageFile = null;
      });
    } catch (e) {
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
                        Text("เพิ่มแคปชั่นและรูปภาพของคุณ", style: TextStyle(fontSize: 16)),
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
                maxLines: 6, // เพิ่มจำนวนบรรทัดสูงสุดเป็น 6
                minLines: 4, // ตั้งค่าจำนวนบรรทัดขั้นต่ำ
                keyboardType: TextInputType.multiline, // ตั้งค่าให้พิมพ์ได้หลายบรรทัด
              ),
              SizedBox(height: 20),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  child: Text("โพสต์", style: TextStyle(fontSize: 18,color: Colors.pink)),
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
