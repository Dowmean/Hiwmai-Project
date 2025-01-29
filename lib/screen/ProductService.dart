import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  final String baseUrl = 'http://10.0.2.2:3000'; // API Base URL

  /// **ตรวจสอบว่าผู้ใช้งานเป็น Admin หรือเจ้าของโพสต์**
  Future<bool> checkRoleOrOwnership(String email, String productId) async {
    final roleCheckUrl = '$baseUrl/checkRoleOrOwnership/$productId';
    try {
      final response = await http.post(
        Uri.parse(roleCheckUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isAuthorized'] ?? false;
      } else {
        throw Exception('Failed to check role or ownership. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error checking role or ownership: $e');
      throw Exception('Error checking role or ownership: $e');
    }
  }

  /// **เพิ่มรายการโปรด**
  Future<void> addFavorite(String email, dynamic productId) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is missing');
    }

    final parsedProductId = _parseProductId(productId);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/toggleFavorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'product_id': parsedProductId,
          'is_favorite': true,
        }),
      );

      if (response.statusCode == 200) {
        //print('Added to favorites successfully');
      } else {
        throw Exception('Failed to add to favorites: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding favorite: $e');
    }
  }

  /// **ลบออกจากรายการโปรด**
  Future<void> removeFavorite(String email, dynamic productId) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is missing');
    }

    final parsedProductId = _parseProductId(productId);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/removeFavorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'product_id': parsedProductId,
        }),
      );

      if (response.statusCode == 200) {
        //print('Removed from favorites successfully');
      } else {
        throw Exception('Failed to remove favorite: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error removing favorite: $e');
    }
  }

  /// **ดึงรายการโปรดด้วยอีเมล**
  Future<List<int>> getFavorites(String email) async {
    //print('Fetching favorites for email: $email');
    final response = await http.get(Uri.parse('$baseUrl/favorites?email=$email'));
    //print('Favorites response: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<int>((item) => item['product_id'] as int).toList();
    } else {
      throw Exception('Failed to fetch favorites: ${response.body}');
    }
  }

  /// **ดึงข้อมูลสินค้าด้วย IDs**
Future<List<dynamic>> fetchProductsByIds(List<int> productIds) async {
  //print('Fetching products for IDs: $productIds');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/getproduct/fetchByIds'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_ids': productIds}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // ใช้ข้อมูล imageUrl จาก Backend โดยตรง
      return data;
    } else {
      throw Exception('Failed to fetch products: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching products: $e');
  }
}

  /// **ลบสินค้า**
  Future<bool> deleteProduct(String productId) async {
    final deleteUrl = '$baseUrl/deleteProduct/$productId';
    try {
      final response = await http.delete(Uri.parse(deleteUrl));
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  /// **แก้ไขสินค้า**
Future<bool> editProduct(
  String productId, {
  required String productName,
  required String productDescription,
  required double price,
  required String category,
  String? imagePath, // Path ของรูปภาพที่ใช้ใน server
}) async {
  final editUrl = '$baseUrl/editProduct/$productId';
  try {
    final requestPayload = {
      "productName": productName,
      "productDescription": productDescription,
      "price": price,
      "category": category,
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      requestPayload["imageUrl"] = imagePath; // ใช้ path แทน base64
    }

    final response = await http.put(
      Uri.parse(editUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to edit product: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error editing product: $e');
  }
}


  /// **ฟังก์ชัน Utility สำหรับ parse product ID**
  int _parseProductId(dynamic productId) {
    try {
      if (productId is String) {
        return int.parse(productId);
      } else if (productId is int) {
        return productId;
      } else {
        throw Exception('Unsupported product ID type');
      }
    } catch (e) {
      throw Exception('Error parsing product ID: $productId');
    }
  }
}
