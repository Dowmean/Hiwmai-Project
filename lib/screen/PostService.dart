import 'package:http/http.dart' as http;
import 'dart:convert';

class PostService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final String apiUrl = 'http://10.0.2.2:3000/checkRoleAndOwnership';
  


  // Function to create a new post
  Future<void> createPost({
    required String firebaseUid,
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    String? imageFile, // Base64-encoded image
  }) async {
    final String apiUrl = '$baseUrl/createpost'; // Full API URL

    // Data to send to the server
    Map<String, dynamic> postData = {
      'firebase_uid': firebaseUid,
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'imageUrl': imageFile, // Can be null if no image
    };

    try {
      print("Sending data: ${json.encode(postData)}");

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(postData),
      );

      // Handle response
      if (response.statusCode == 201) {
        print("Post created successfully: ${response.body}");
      } else {
        print("Failed to create post: ${response.statusCode}, ${response.body}");
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
  final url = Uri.parse('http://10.0.2.2:3000/favorites?email=$email'); // เปลี่ยน URL
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<int>((item) => item['product_id'] as int).toList();
    } else {
      print('Failed to fetch favorites: ${response.body}');
      throw Exception('Failed to fetch favorites');
    }
  } catch (e) {
    print('Error fetching favorites: $e');
    throw Exception('Error fetching favorites: $e');
  }
}

Future<List<dynamic>> fetchProductsByIds(List<int> productIds) async {
  final url = Uri.parse('http://10.0.2.2:3000/getproduct/fetchByIds');
  try {
    print('Fetching products for IDs: $productIds');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_ids': productIds}),
    ).timeout(Duration(seconds: 10)); // เพิ่ม timeout

    if (response.statusCode == 200) {
      final List<dynamic> products = jsonDecode(response.body);
      print('Fetched products: $products');
      return products;
    } else {
      print('Failed to fetch products: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch products');
    }
  } catch (e) {
    print('Error fetching products: $e');
    throw Exception('Error fetching products: $e');
  }
}




  toggleFavoriteStatus({required String userId, required String productId, required bool isFavorite}) {}
}
