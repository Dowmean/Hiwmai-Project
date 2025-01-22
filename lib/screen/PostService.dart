import 'package:http/http.dart' as http;
import 'dart:convert';

class PostService {
  final String baseUrl = 'http://10.0.2.2:3000'; 
  final String apiUrl = 'http://10.0.2.2:3000/checkRoleAndOwnership';
  
  get imagePath => null;
  


  // Function to create a new post
Future<void> createPost({
    required String firebaseUid,
    required String category,
    required String productName,
    required String productDescription,
    required double price,
    required double shipping, // เพิ่มฟิลด์ shipping
    required double carry, // เพิ่มฟิลด์ carry
    String? imageFile, // Base64-encoded image
  }) async {
    final String apiUrl = '$baseUrl/createpost'; // Full API URL

    // Data to send to the server
Map<String, dynamic> postData = {
  'productName': productName,
  'productDescription': productDescription,
  'price': price,
  'shipping': shipping,
  'carry': carry,
  'category': category,
  'imageUrl': imageFile != null && imageFile.isNotEmpty ? imageFile : '',
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


  deletePost(product) {}

  editPost(product, {required String productName, required String productDescription, required price, required shipping, required carry, required String category, required imagePath}) {}
}


  // ฟังก์ชันสำหรับแก้ไขโพสต์
Future<bool> editPost(
  int id, {
  required String productName,
  required String productDescription,
  required double price,
  required double shipping,
  required double carry,
  required String category,
  required String? imagePath,
}) async {
  Map<String, dynamic> postData = {
    'productName': productName,
    'productDescription': productDescription,
    'price': price,
    'shipping': shipping,
    'carry': carry,
    'category': category,
    'imageUrl': imagePath != null && imagePath.isNotEmpty ? imagePath : null,
  };

  try {
    final String apiUrl = 'http://10.0.2.2:3000/editpost/$id';
    print("Sending data to backend: $postData");

    var response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(postData),
    );

    if (response.statusCode == 200) {
      print("Post updated successfully: ${response.body}");
      return true;
    } else {
      print("Failed to update post: ${response.statusCode}, ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error updating post: $e");
    return false;
  }
}



  // ฟังก์ชันสำหรับลบโพสต์
Future<bool> deletePost(int id) async {
  try {
    final String apiUrl = 'http://10.0.2.2:3000/deletepost/$id';
    var response = await http.delete(
      Uri.parse(apiUrl),
    );

    if (response.statusCode == 200) {
      print("Post deleted successfully: ${response.body}");
      return true;
    } else {
      print("Failed to delete post: ${response.statusCode}, ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error deleting post: $e");
    return false;
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
