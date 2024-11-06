import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PostService {
  final String apiUrl = 'http://10.0.2.2:3000/createpost'; // URL สำหรับการสร้างโพสต์

  // Function to create a post
  Future<void> createPost({
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    File? imageFile,
  }) async {
    List<int>? imageBytes;

    // Convert image to binary if provided
    if (imageFile != null) {
      imageBytes = await imageFile.readAsBytes();
    }

    // Build the post data
    Map<String, dynamic> postData = {
      'userName': 'user@example.com', // Example username
      'userId': '12345', // Example user ID
      'category': category,
      'productName': productName,
      'productDescription': productDescription,
      'price': price,
      'imageUrl': imageBytes != null ? base64Encode(imageBytes) : null, // Base64 image data
    };

    // Send POST request to the backend
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
  Future<void> editPost(int id, {
    required String productName,
    required String productDescription,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      Map<String, dynamic> postData = {
        'productName': productName,
        'productDescription': productDescription,
        'price': price,
        'category': category,
        'imageUrl': imageUrl ?? '',
      };

      // ใช้ URL โดยตรงสำหรับแก้ไขโพสต์ โดยรวม id ใน URL
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
    try {
      // ใช้ URL โดยตรงสำหรับลบโพสต์ โดยรวม id ใน URL
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
}
