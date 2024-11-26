import 'package:http/http.dart' as http;
import 'dart:convert';
class ProductService {
  final String apiUrl = 'http://10.0.2.2:3000/favorites';
  final String toggleFavoriteUrl = 'http://10.0.2.2:3000/toggleFavorite';
  final String fetchProductsByIdsUrl = 'http://10.0.2.2:3000/getproduct/fetchByIds'; // เพิ่มตัวแปรนี้

  // Fetch all products
  Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load products: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching products: $e");
    }
  }


  // Add to favorites
  Future<void> addFavorite(String email, dynamic productId) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is missing');
    }

    final parsedProductId = _parseProductId(productId);

    try {
      final response = await http.post(
        Uri.parse(toggleFavoriteUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'product_id': parsedProductId,
          'is_favorite': true,
        }),
      );

      if (response.statusCode == 200) {
        print('Added to favorites successfully');
      } else {
        throw Exception('Failed to add to favorites: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding favorite: $e');
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String email, dynamic productId) async {
    if (email.trim().isEmpty) {
      throw Exception('Email is missing');
    }

    final parsedProductId = _parseProductId(productId);

    try {
      final response = await http.post(
        Uri.parse(toggleFavoriteUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'product_id': parsedProductId,
          'is_favorite': false,
        }),
      );

      if (response.statusCode == 200) {
        print('Removed from favorites successfully');
      } else {
        throw Exception('Failed to remove from favorites: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error removing favorite: $e');
    }
  }

  // Fetch favorites by email
  Future<List<int>> getFavorites(String email) async {
    print('Fetching favorites for email: $email');
    final response = await http.get(Uri.parse('$apiUrl?email=$email'));
    print('Favorites response: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<int>((item) => item['product_id'] as int).toList();
    } else {
      throw Exception('Failed to fetch favorites: ${response.body}');
    }
  }
  // Fetch products by IDs
  Future<List<dynamic>> fetchProductsByIds(List<int> productIds) async {
    print('Fetching products for IDs: $productIds');
    final response = await http.post(
      Uri.parse(fetchProductsByIdsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_ids': productIds}),
    );
    print('Products response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch products: ${response.body}');
    }
  }



  // Delete product
  Future<bool> deleteProduct(String productId) async {
    final deleteUrl = 'http://10.0.2.2:3000/deleteProduct/$productId';
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

  // Edit product
  Future<bool> editProduct(
    String productId, {
    required String productName,
    required String productDescription,
    required double price,
    required String category,
    required String imageUrl,
  }) async {
    final editUrl = 'http://10.0.2.2:3000/editProduct/$productId';
    try {
      final response = await http.put(
        Uri.parse(editUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "productName": productName,
          "productDescription": productDescription,
          "price": price,
          "category": category,
          "imageUrl": imageUrl,
        }),
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

 // Utility function to parse product ID
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