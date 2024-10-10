import 'package:firebase_auth/firebase_auth.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:firebase_storage/firebase_storage.dart';
import 'package:loginsystem/model/PostModel.dart';
import 'dart:io';

class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          _storage.ref().child('product_images/$fileName');
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
