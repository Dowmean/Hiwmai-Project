import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PostService {
  final String apiUrl = 'http://10.0.2.2:3000/createpost'; // URL สำหรับการสร้างโพสต์

  // ฟังก์ชันสำหรับสร้างโพสต์ใหม่
  Future<void> createPost({
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    File? imageFile,
  }) async {
    // ตรวจสอบและแปลงรูปภาพเป็น binary
    List<int>? imageBytes;
    if (imageFile != null) {
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        print("Error reading image file: $e");
        return;
      }
    }

    // ข้อมูลของโพสต์
    Map<String, dynamic> postData = {
      'userName': 'user@example.com', // ใช้ชื่อผู้ใช้ตัวอย่าง
      'userId': '12345', // ใช้ ID ผู้ใช้ตัวอย่าง
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'imageUrl': imageBytes != null ? base64Encode(imageBytes) : null, // แปลงรูปภาพเป็น base64
    };

    // ส่งคำขอ POST ไปยัง backend
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        print("Post created successfully");
      } else {
        print("Failed to create post: ${response.body}");
      }
    } catch (e) {
      print("Error submitting post: $e");
    }
  }

  // ฟังก์ชันสำหรับแก้ไขโพสต์
  Future<void> editPost(
    int id, {
    required String productName,
    required String productDescription,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    // ข้อมูลของโพสต์ที่จะส่ง
    Map<String, dynamic> postData = {
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'category': category,
      'imageUrl': imageUrl ?? '',
    };

    // ส่งคำขอ PUT ไปยัง backend เพื่อแก้ไขโพสต์
    try {
      var response = await http.put(
        Uri.parse('http://10.0.2.2:3000/editpost/$id'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        print("Post updated successfully");
      } else {
        print("Failed to update post: ${response.body}");
      }
    } catch (e) {
      print("Error updating post: $e");
    }
  }

  // ฟังก์ชันสำหรับลบโพสต์
  Future<void> deletePost(int id) async {
    // ส่งคำขอ DELETE ไปยัง backend เพื่อทำการลบโพสต์
    try {
      var response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/deletepost/$id'),
      );

      if (response.statusCode == 200) {
        print("Post deleted successfully");
      } else {
        print("Failed to delete post: ${response.body}");
      }
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  Future<List<int>> getFavorites(String email) async {
  // API ดึงรายการโปรดตาม email
  final response = await http.get(Uri.parse('http://example.com/favorites?email=$email'));
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map<int>((item) => item['product_id'] as int).toList();
  } else {
    throw Exception('Failed to fetch favorites');
  }
}
Future<List<dynamic>> fetchProductsByIds(List<int> productIds) async {
  final response = await http.post(
    Uri.parse('http://example.com/productsByIds'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'product_ids': productIds}),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch products');
  }
}


  toggleFavoriteStatus({required String userId, required String productId, required bool isFavorite}) {}
}
