import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PostService {
  final String baseUrl = 'http://10.0.2.2:3000';

  // สร้างโพสต์ใหม่
  Future<void> createPost({
    required String firebaseUid,
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    required double shipping,
    required double carry,
    String? imageFile, // Base64-encoded image
  }) async {
    final String apiUrl = '$baseUrl/createpost';

    Map<String, dynamic> postData = {
      'firebase_uid': firebaseUid,
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'shipping': shipping,
      'carry': carry,
      'imageUrl': imageFile ?? '', // ใช้ค่าว่างถ้าไม่มีรูป
    };

    try {
      print("🚀 Sending data: \${json.encode(postData)}");

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(postData),
      );

      if (response.statusCode == 201) {
        print("✅ Post created successfully: \${response.body}");
      } else {
        print("❌ Failed to create post: \${response.statusCode}, \${response.body}");
      }
    } catch (e) {
      print("⚠️ Error submitting post: $e");
    }
  }

  // แก้ไขโพสต์
Future<void> editPost(
  int id, {
  required String productName,
  required String productDescription,
  required double price,
  required double shipping,
  required double carry,
  required String category,
  String? imageFile, // Base64 or existing file name
}) async {
  final String apiUrl = '$baseUrl/editpost/$id';

  // ✅ ถ้าเป็น Base64, ต้องล้าง data:image/jpeg;base64, ออกก่อน
  if (imageFile != null && imageFile.startsWith('data:image')) {
    imageFile = imageFile.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
  }

  Map<String, dynamic> postData = {
    'productName': productName,
    'productDescription': productDescription,
    'price': price,
    'shipping': shipping,
    'carry': carry,
    'category': category,
    'imageUrl': imageFile ?? '', // ✅ ใช้ค่าว่างถ้าไม่มีรูปใหม่
  };

  try {
    print("🚀 Sending edit request to $apiUrl");
    print("🛠️ Payload: ${json.encode(postData)}");

    var response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(postData),
    );

    print("📢 Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      print("✅ Post updated successfully: ${response.body}");
    } else {
      print("❌ Failed to update post: ${response.statusCode}, ${response.body}");
    }
  } catch (e) {
    print("⚠️ Error updating post: $e");
  }
}


  // ลบโพสต์
  Future<void> deletePost(int id) async {
    final String apiUrl = '$baseUrl/deletepost/$id';
    try {
      print("🚀 Deleting post ID: $id");

      var response = await http.delete(
        Uri.parse(apiUrl),
      );

      if (response.statusCode == 200) {
        print("✅ Post deleted successfully: \${response.body}");
      } else {
        print("❌ Failed to delete post: \${response.statusCode}, \${response.body}");
      }
    } catch (e) {
      print("⚠️ Error deleting post: $e");
    }
  }

  // ดึงโพสต์ตาม ID
  Future<List<dynamic>> fetchProductsByIds(List<int> productIds) async {
    final url = Uri.parse('$baseUrl/getproduct/fetchByIds');

    try {
      print('🚀 Fetching products for IDs: $productIds');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'product_ids': productIds}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> products = jsonDecode(response.body);
        print('✅ Fetched products: $products');
        return products;
      } else {
        print('❌ Failed to fetch products: \${response.statusCode} - \${response.body}');
        throw Exception('Failed to fetch products');
      }
    } catch (e) {
      print('⚠️ Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }
}
